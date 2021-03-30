
function getParameterByName(name) {
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);
    return results == null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
}
function getParameterByNameFromURL(name,url) {
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(url);
    return results == null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
}

$(document).ready(function(){
	var container = $("#container");

	var width = container.width();
	var height = container.height();

	var x = d3.scale.linear()
		.domain([0, width])
		.range([0, width]);
	var y = d3.scale.linear()
		.domain([0, height])
		.range([0, height]);
	
	var zoom = d3.behavior.zoom()
		.x(x)
		.y(y)
		.scaleExtent([0.06, 10])
		.on("zoom", zoomed);

	function zoomed() {
		svgbox.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
		var CurrScale = zoom.scale();
		if(CurrScale < 0.9){
			svgbox.selectAll(".textlong").style("visibility", "hidden");
			svgbox.selectAll(".textshort").style("visibility", "visible");
			svgbox.selectAll(".link").style("stroke-width", "3px");
		} else {
			svgbox.selectAll(".textlong").style("visibility", "visible");
			svgbox.selectAll(".textshort").style("visibility", "hidden");
			svgbox.selectAll(".link").style("stroke-width", "2px");
		}
	}

	var svg = d3.select("#container").append("svg")
		.attr("width", "100%")
		.attr("height", "100%")
		.append("g")
		.call(zoom);
	svg.on('click', function () {
		if ($('#content').css('display') !== 'none') { 
			$("#content").toggle( "slide", {direction:"up"}, 300 );
		};
	});

	var rect = svg.append("rect")
		.attr("width", "100%")
		.attr("height", "100%")
		.style("fill", "none")
		.style("pointer-events", "all");

	var svgbox = svg.append("g");

	// SUN2
	var imgsun2 = svgbox.append("circle")
		.attr("cx", 0)
		.attr("cy", 0)
		.attr("r", 0)
		.style("fill", "blue");
	
	var nodes = [],
		links = [];

	var node = svgbox.selectAll(".node"),
		photo = svgbox.append("defs").selectAll(".photo"),
		shape = svgbox.selectAll(".shape"),
		link = svgbox.selectAll(".link"),
		text = svgbox.selectAll(".text"),
		duration = 0;
	var ellrx = 31.5,
		ellry = 40.5,
		cirr = 20;
	

	var PersArray = d3.values(persons),
		XMax = d3.max( PersArray, function(e) { return parseInt(e.fx); }),
		XMin = d3.min( PersArray, function(e) { return parseInt(e.fx); }),
		YMax = d3.max( PersArray, function(e) { return parseInt(e.fy); }),
		YMin = d3.min( PersArray, function(e) { return parseInt(e.fy); });
	StartScalePosPlus( width/(XMax - XMin+500), (XMax+XMin)/2, (YMax+YMin)/2 );
		
	for (var pid in persons) {
		var person = persons[pid];
		person.x = person.fx;
		person.y = person.fy;
		nodes.push(person);
	}
	for (var fid in families) {
		var family = families[fid];
		family.x = family.fx;
		family.y = family.fy;
		nodes.push(family);

		for (var id in family.parents) {
			var parent = persons[family.parents[id]];
			links.push({source: family, target: parent});
		}
		for (var id in family.children) {
			var child = persons[family.children[id]];
			links.push({source: family, target: child});
		}
	}
	
	$('#btnSearch').on('click', function (e) {
			$("#content").toggle( "slide", {direction:"up"}, 300 );
	});

	
	start();

	BodyPageLinkClickEvent();
	var personid = getParameterByNameFromURL('person',location.search);
	GoToPerson(personid);
//----------------------------------------------------------------------------------------
//	Paint
//----------------------------------------------------------------------------------------


	function start() {

		text = text.data(nodes.filter(function(n){ return (n.name || n.birth || n.death); }));
		text.enter().append("text")
			.attr("shape", function(d){ if(d.photo){return "ellipse"}else{return "circle"}; })
			.attr("x", function(d) { return d.x; })
			.attr("y", function(d) { return d.y; })
			.attr("namefirst", function(d){ if(d.name && d.name.first){return d.name.first}; })
			.attr("namelast", function(d){ if(d.name && d.name.last){return d.name.last}; })
			.attr("namemiddle", function(d){ if(d.name && d.name.middle){return d.name.middle}; })
			.attr("datebirth", function(d){ if(d.datebirth){return d.datebirth}; })
			.attr("datedeath", function(d){ if(d.datedeath){return d.datedeath}; })
			.call(wrap);

		text.style("text-anchor", "middle").style("text-shadow", "0 0 10px #e5ffe5").style("cursor", "pointer");
		svgbox.selectAll(".textlong").style("font-size", "12px").style("visibility", "hidden");
		svgbox.selectAll(".textshort").style("font-size", "18px");
	
		photo = photo.data(nodes.filter(function(d){ return (d.photo)}), function(d) {return d.id;});
		photo.enter().append("pattern")
					.attr("id", function(d){ return ("ptn_"+d.id) })
					.attr("patternUnits", "userSpaceOnUse")
					.attr("x", function(d) { return d.x-ellrx; })
					.attr("y", function(d) { return d.y-ellry; })
					.attr("width", ellrx*2)
					.attr("height", ellry*2)
					.append("svg:image")
					.attr("xlink:href", function(d) { return "photo/"+d.photo; })
					.attr("width", ellrx*2)
					.attr("height", ellry*2);
		photo.exit().remove();
		
		
		shape = shape.data(nodes.filter(function(d){ return (d.photo)}), function(d) {return d.id;});
		shape.enter().append("ellipse")
					.attr("class", "shape none")
					.attr("cx", function(d) { return d.x; })
					.attr("cy", function(d) { return d.y; })
					.attr("rx", ellrx)
					.attr("ry", ellry)
					.attr("fill", function(d) { return "url(#ptn_"+d.id+")"; })
					.append("title").text(function(d) { if(d.name && d.name.display){return d.name.display;}});
		shape.exit().remove();
		
		shape = shape.data(nodes, function(d) {return d.id;});
		shape.enter().append("circle")
			.attr("id", function(d) { return d.id; })
			.attr("class", function(d) {
				if(d.gender){if(d.gender==="M"){return "shape male";}else{return "shape female";}
				} else {return "shape family";}})
			.attr("cx", function(d) { return d.x; })
			.attr("cy", function(d) { return d.y; })
			.attr("r", '20px')
			.append("title").text(function(d) { if(d.name && d.name.display){return d.name.display;}} );
		shape.exit().remove();
		

		text.exit().remove();
		
		link = link.data(links, function(d) { return d.source.id + "-" + d.target.id; });
		link.enter().insert("svg:path", ".shape").attr("class", "link")
			.attr('d', function(d) {
				var x1 = parseInt(d.source.x),
					y1 = parseInt(d.source.y),
					x2 = parseInt(d.target.x),
					y2 = parseInt(d.target.y),
					y3 = 0,
					ry = cirr,
					dname = 0,
					ddate = 0;
					
					if(d.target.name){
						dname = 28;
						if(d.target.name.first && d.target.name.middle && d.target.name.last){
							dname += 12;
						}
					}
					if(d.target.datebirth || d.target.datedeath){
						ddate = 28;
					}
					
					if(d.target.photo) {
						ry = ellry;
					}
					if( y1 > y2 ){
						y2 += (ry + dname);
					} else {
						y2 -= (ry + ddate);
					}
					y3 = (y1+y2)/2;
				return ("M"+x1+","+y1+" C"+x1+","+y3+" "+x2+","+y3+" "+x2+","+y2)});
		link.exit().remove();
		
	}

	
	function wrap() {
		text.each(function() {
			var text = d3.select(this),
				shape = text.attr("shape"),
				namelast = text.attr("namelast"),
				namefirst = text.attr("namefirst"),
				namemiddle = text.attr("namemiddle"),
				datebirth = text.attr("datebirth"),
				datedeath = text.attr("datedeath"),
				lineNumber = 0,
				lineHeight = 1, // ems
				x = text.attr("x"),
				y = parseInt(text.attr("y")),
				datey = 0,
				namey = 0,
				dy = 0;
			//console.log(shape);
			text.text(null);

			if(shape === "ellipse") {
				datey = y - ellry +8;
				namey = y + ellry +2;
			} else {
				datey = y - cirr +8;
				namey = y + cirr +2;
			}
			
			
			//textlong
			var dateshort = "";
			lineNumber = 0;
			if(datedeath !== null) {
				text.append("tspan").attr("class", "textlong").attr("x", x).attr("y", datey).attr("dy", --lineNumber * lineHeight + dy + "em").text(datedeath);
			}
			if(datebirth !== null) {
				text.append("tspan").attr("class", "textlong").attr("x", x).attr("y", datey).attr("dy", --lineNumber * lineHeight + dy + "em").text(datebirth);
				if(datedeath !== null) {
					dateshort = datebirth.substr(datebirth.length - 4) + "-" + datedeath.substr(datedeath.length - 4);
				} else {
					dateshort = datebirth.substr(datebirth.length - 4);
				}
			} else {
				if(datedeath !== null) {
					text.append("tspan").attr("class", "textlong").attr("x", x).attr("y", datey).attr("dy", --lineNumber * lineHeight + dy + "em").text("???");
					dateshort = "???-" + datedeath.substr(datedeath.length - 4);
				}
			}
			//textshort
			lineNumber = -1;
			//dateshort = "1945-1999";
			if(dateshort !== "") {
				text.append("tspan").attr("class", "textshort").attr("x", x).attr("y", datey+5).attr("dy", lineNumber * lineHeight + dy + "em").text(dateshort);
			}

			//textlong
			lineNumber = -0.2;
			if(namefirst !== null) {
				text.append("tspan").attr("class", "textlong").attr("x", x).attr("y", namey).attr("dy", ++lineNumber * lineHeight + dy + "em").text(namefirst);
			}
			if(namemiddle !== null) {
				text.append("tspan").attr("class", "textlong").attr("x", x).attr("y", namey).attr("dy", ++lineNumber * lineHeight + dy + "em").text(namemiddle);
			}
			if(namelast !== null) {
				text.append("tspan").attr("class", "textlong").attr("x", x).attr("y", namey).attr("dy", ++lineNumber * lineHeight + dy + "em").text(namelast);
			}
			//textshort
			lineNumber = 0.6;
			lineHeight = 1.2;
			if(namefirst !== null) {
				text.append("tspan").attr("class", "textshort").attr("x", x).attr("y", namey+5).attr("dy", lineNumber * lineHeight + dy + "em").text(namefirst); //.toUpperCase()
			}
			if(namelast !== null) {
				text.append("tspan").attr("class", "textshort").attr("x", x).attr("y", namey).attr("dy", ++lineNumber * lineHeight + dy + "em").text(namelast);
			}
		});
	}	
	
	function StartScalePos(z,x,y) {
		var dx = container.width()/2-x*z;
		var dy = container.height()/2-y*z;
		zoom.translate([dx,dy]).scale(z);
		svgbox.attr("transform", "translate("+dx+","+dy+"), scale("+z+")");
		//svg.select(".x.axis").call(xAxis);
		//svg.select(".y.axis").call(yAxis);
	}
	
	function StartScalePosPlus(z,x,y) {
		var dx = container.width()/2-x*z;
		var dy = container.height()/2-y*z;
		zoom
			.translate([dx,dy])
			.scale(z);
		svgbox
			.transition()
			.duration(1000)
			.attr("transform", "translate("+dx+","+dy+"), scale("+z+")");
	}

	function GoToPerson(personid) {
		if( personid !== null && personid !== ""  ){
			var IndId = personid;
			if( persons[IndId] != null ) {
				var ObjPosX = persons[IndId].x;
				var ObjPosY = persons[IndId].y;

				var CurrScale = 0.5;
				
				zoom.
					translate([((container.width())/2-ObjPosX*CurrScale),((container.height())/2-ObjPosY*CurrScale)])
					.scale(CurrScale);
				svgbox
					.transition()
					.duration(750)
					.attr("transform", "translate("+((container.width())/2-ObjPosX*CurrScale)+","+((container.height())/2-ObjPosY*CurrScale)+"), scale("+CurrScale+")")
					.each("end", function() {
						imgsun2
							.attr("cx", ObjPosX)
							.attr("cy", ObjPosY)
							.attr("r", 0)
							.style("opacity", 1)
							.transition()
							.duration(750)
							.ease('linear')
							.attr("r", 150)
							.style("opacity", 0)
							.each("end", function() {
								imgsun2
								.attr("r", 0)
								.style("opacity", 1)
								.transition()
								.duration(750)
								.ease('linear')
								.attr("r", 150)
								.style("opacity", 0)
								.each("end", function() {
									imgsun2
									.attr("r", 0)
									.style("opacity", 1)
									.transition()
									.duration(750)
									.ease('linear')
									.attr("r", 150)
									.style("opacity", 0);
								});
							});
						});
				}
		};	
	}
	
	function BodyPageLinkClickEvent() {
		$('#content-body').find('a').on('click', function (e) {
			var url = $(this).attr('href');
			var personid = getParameterByNameFromURL('person',url);
			if( personid !== null && personid !== ""  ){
				if ($('#content').css('display') !== 'none') { 
					$("#content").toggle( "slide", {direction:"up"}, 300 );
					setTimeout( GoToPerson(personid), 300);
				} else {
					GoToPerson(personid);
				}
				if(url != window.location){
					window.history.pushState(null, null, url);
				}
				return false;
			}
		});
	}
	$( window ).resize(function() {
		var height = $("#container").height() - $("#header").height() - $("#content-header").height() -110;
		$("#content-body").css('max-height', height);
	});
	var height = $("#container").height() - $("#header").height() - $("#content-header").height() -110;
	$("#content-body").css('max-height', height);
	
	function familiesmenu() {
		$("#families a.lifamily").click(function(){
			$("#families ul ul").slideUp();
			if(!$(this).next().is(":visible"))
			{
				$(this).next().slideDown();
			}
		});
	}
	familiesmenu();
	
});