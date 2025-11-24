document.addEventListener("DOMContentLoaded", () => {

    const svg = document.getElementById("svgInput");
    const layer = document.getElementById("pointsLayer");
    const Rselect = document.getElementById("pointForm:r");
    const jsonHolder = document.getElementById("areaSvg:pointsJson");
    console.log(svg, layer, Rselect, jsonHolder);

    const xHidden = document.getElementById("svgX");
    const yHidden = document.getElementById("svgY");
    const rHidden = document.getElementById("svgR");
    const submitBtn = document.getElementById("svgSubmit");

    const SCALE = 120;
    const CX = 200;
    const CY = 200;

    function xyToSvg(x, y, r) {
        const k = SCALE / r;
        return {
            sx: CX + x * k,
            sy: CY - y * k
        };
    }

    function drawPoint(x, y, r, hit) {
        const pos = xyToSvg(x, y, r);

        const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
        circle.setAttribute("cx", pos.sx);
        circle.setAttribute("cy", pos.sy);
        circle.setAttribute("r", 4);
        circle.setAttribute("fill", hit ? "limegreen" : "red");

        layer.appendChild(circle);
    }

    function clearPoints() {
        layer.innerHTML = "";
    }

    window.redraw = function() {
        let history = [];
        try {
            history = JSON.parse(jsonHolder.textContent || "[]");
        } catch (_) {}

        const r = parseFloat(Rselect.value);
        clearPoints();
        history.forEach(p => drawPoint(p.x, p.y, r, p.hit));
    }

    svg.addEventListener("click", ev => {
        const r = parseFloat(Rselect.value);
        if (!r) {
            alert("Сначала выберите R");
            return;
        }

        const svgEl = ev.currentTarget;
        const pt = svgEl.createSVGPoint();
        pt.x = ev.clientX; pt.y = ev.clientY;
        const ctm = svgEl.getScreenCTM();
        if (!ctm) return null;
        const svgPt = pt.matrixTransform(ctm.inverse());

        const k = r / SCALE ;

        const x = Number(((svgPt.x - CX) * k).toFixed(2));
        const y = Number(((CY - svgPt.y) * k).toFixed(2));

        xHidden.value = x;
        yHidden.value = y;
        rHidden.value = r;

        submitBtn.click();
    });

    Rselect.addEventListener("change", redraw);

    function onAjaxUpdate (data) {
        if (data.status === "success") {
            redraw();
        }
    };

    redraw();
});
