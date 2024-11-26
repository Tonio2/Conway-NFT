// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import { Utils } from './Utils.sol';
import "hardhat/console.sol";

contract AnimatedSVGToken is ERC721, Ownable {
    struct Seed {
        uint8[] bits;
        uint256 lineLength;
    }

    uint256 private _nextTokenId;
    mapping(uint256 => Seed) private gameConfigs;

    constructor(address initialOwner)
        ERC721("AnimatedSVGToken", "ASVG")
        Ownable(initialOwner)
    {}

    function safeMint(address to, uint256 lineLength, uint8[] calldata bits) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        gameConfigs[tokenId] = Seed(bits, lineLength);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        string memory svg = _generateSVG(gameConfigs[tokenId]);

        // Encode SVG into Base64
        string memory image = string.concat(
            '"image":"data:image/svg+xml;base64,',
            Utils.encode(bytes(svg)),
            '"'
        );

        string memory animated_svg = _generateAnimatedSVG();
        console.log(animated_svg);

        string memory animation_url = string.concat(
            '"animation_url":"data:text/html;base64,',
            Utils.encode(bytes(animated_svg)),
            '"'
        );

        // Create metadata JSON
        string memory json = string.concat(
            '{"name": "AnimatedSVG #',
            Utils.toString(tokenId),
            '", "description": "An on-chain animated SVG NFT.", ',
            image, ', ', animation_url,
            '}'
        );

        // // option #1 - as JSON
        // return string.concat('data:application/json;utf8,', json);

        // option #2 - as BASE64 encoded
        return
            string.concat(
                "data:application/json;base64,",
                Utils.encode(bytes(json))
            );   
    }

    function _generateSVG(Seed memory config) pure internal returns (string memory) {
        int256 svgSize = 800;
        int256 cellSize = 20;
        int256 minX; int256 minY; int256 maxX; int256 maxY;

        int256[2][] memory activeCells = _generateActiveCells(config);
        (minX, minY, maxX, maxY) = _maxCoordinates(activeCells);

        // Header and footer
        console.log(Utils.toString(minX));
        int256 viewStartX = -(svgSize / 2) + (minX + (maxX - minX) / 2) * cellSize;
        int256 viewStartY = -(svgSize / 2) + (minY + (maxY - minY) / 2) * cellSize;
        console.log(Utils.toString(viewStartX));
        string memory svgHeader = string.concat(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='",
            Utils.toString(viewStartX), " ", Utils.toString(viewStartY), " ", 
            Utils.toString(svgSize), " ", Utils.toString(svgSize), 
            "' width='", Utils.toString(svgSize), 
            "' height='", Utils.toString(svgSize), "'>"
        );
        string memory svgFooter = "</svg>";

        // Generate grid
        string memory grid = _generateGrid(svgSize, cellSize, viewStartX, viewStartY);

        // Generate cells
        string memory cells = _generateCells(activeCells, cellSize);

        return string(abi.encodePacked(svgHeader, grid, cells, svgFooter));
    }

    function _generateActiveCells(Seed memory config) pure internal returns (int256[2][] memory) {
        int256[2][] memory activeCells = new int256[2][](config.bits.length * 8);
        int256 x;
        int256 y;
        uint256 count = 0;

        for (uint256 i = 0; i < config.bits.length; i++) {
            for (uint256 j = 0; j < 8; j++) {
                bool isAlive = (config.bits[i] & (1 << uint256(7 - j))) != 0;
                x = int256((i * 8 + j) % config.lineLength);
                y = int256((i * 8 + j) / config.lineLength);
                if (isAlive) {
                    activeCells[count] = [x,y];
                    count++;
                }
            }
        }
        
        int256[2][] memory res = new int256[2][](count);
        for (uint256 i = 0; i < count; i++) {
            res[i] = activeCells[i];
        }

        return res;
    }

    function _maxCoordinates(int256[2][] memory activeCells) pure internal returns (int256, int256, int256, int256) {
        int256 minX = activeCells[0][0];
        int256 maxX = activeCells[0][0];
        int256 minY = activeCells[0][1];
        int256 maxY = activeCells[0][1];

        for (uint256 i = 1; i < activeCells.length; i++) {
            int256 x = activeCells[i][0];
            int256 y = activeCells[i][1];

            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
        }

        return (minX, minY, maxX, maxY);
    }



    function _generateGrid(int256 svgSize, int256 cellSize, int256 viewStartX, int256 viewStartY) pure internal returns (string memory) {
        string memory grid;
        int256 numLines = svgSize / cellSize;
        int256 maxX = viewStartX + 800;
        int256 maxY = viewStartY + 800;

        for (int256 i = 0; i < numLines; i++) {
            grid = string.concat(
                grid,
                "<line x1='", Utils.toString(viewStartX + i * cellSize), 
                "' x2='", Utils.toString(viewStartX + i * cellSize), 
                "' y1='", Utils.toString(viewStartY), 
                "' y2='", Utils.toString(maxY), 
                "' stroke='gray' stroke-width='1' />",
                "<line y1='", Utils.toString(viewStartY + i * cellSize), 
                "' y2='", Utils.toString(viewStartY + i * cellSize), 
                "' x1='", Utils.toString(viewStartX), 
                "' x2='", Utils.toString(maxX), 
                "' stroke='gray' stroke-width='1' />"
            );
        }

        return grid;
    }

    function _generateCells(int256[2][] memory activeCells, int256 cellSize) pure internal returns (string memory) {
        string memory cells;

        for (uint256 i = 0; i < activeCells.length; i++) {
            cells = string.concat(
                cells,
                "<rect x='", Utils.toString(activeCells[i][0] * cellSize), 
                "' y='", Utils.toString(activeCells[i][1] * cellSize), 
                "' width='", Utils.toString(cellSize), 
                "' height='", Utils.toString(cellSize), 
                "' />"
            );
        }

        return cells;
    }

    function _generateAnimatedSVG() pure internal returns(string memory) {
        return string(abi.encodePacked(
            "<html><body style='margin:0;'><script src='https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js'></script><script>const scene=new THREE.Scene,camera=new THREE.PerspectiveCamera(75,window.innerWidth/window.innerHeight,.1,1e3),renderer=new THREE.WebGLRenderer;renderer.setSize(window.innerWidth,window.innerHeight),document.body.appendChild(renderer.domElement);const radius=1,segments=64,circleGeometry=new THREE.CircleGeometry(1,64),material=new THREE.MeshBasicMaterial({color:16711680,side:THREE.DoubleSide}),circle=new THREE.Mesh(circleGeometry,material);function animate(){requestAnimationFrame(animate),renderer.render(scene,camera)}scene.add(circle),camera.position.z=5,animate(),window.addEventListener('resize',()=>{camera.aspect=window.innerWidth/window.innerHeight,camera.updateProjectionMatrix(),renderer.setSize(window.innerWidth,window.innerHeight)});</script></body></html>"
        ));
//        return string(
//          abi.encodePacked(
//                "<html><body style='margin:0;'><script src='https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js'></script><script>const scene=new THREE.Scene,camera=new THREE.PerspectiveCamera(75,window.innerWidth/window.innerHeight,.1,1e3),renderer=new THREE.WebGLRenderer;renderer.setSize(window.innerWidth,window.innerHeight),document.body.appendChild(renderer.domElement);const radius=1,segments=64,circleGeometry=new THREE.CircleGeometry(1,64),material=new THREE.MeshBasicMaterial({color:16711680,side:THREE.DoubleSide}),circle=new THREE.Mesh(circleGeometry,material);function animate(){requestAnimationFrame(animate),renderer.render(scene,camera)}scene.add(circle),camera.position.z=5,animate(),window.addEventListener('resize',()=>{camera.aspect=window.innerWidth/window.innerHeight,camera.updateProjectionMatrix(),renderer.setSize(window.innerWidth,window.innerHeight)});</script><script>const cellSize=20,frameDuration=200;let activeCells=new Set,isDragging=!1,dragStart={x:0,y:0},viewBoxStart={x:0,y:0};const svgConfig={width:800,height:800,viewBox:{x:-400,y:-400,width:800,height:800},gridLines:[],cells:[]};function getNeighbors(e,t){let i=[-1,0,1],g=[];for(let n of i)for(let o of i)(0!==n||0!==o)&&g.push(`${e+n},${t+o}`);return g}function nextGeneration(){let e=new Map;activeCells.forEach(t=>{let[i,g]=t.split(',').map(Number);getNeighbors(i,g).forEach(t=>{e.set(t,(e.get(t)||0)+1)})});let t=new Set;e.forEach((e,i)=>{(3===e||2===e&&activeCells.has(i))&&t.add(i)}),activeCells=t}function decodeSeed(e,t){activeCells.clear();let i=e.map(e=>e.toString(2).padStart(8,'0')).join('');for(let g=0;g<i.length;g++)if('1'===i[g]){let n=g%t,o=Math.floor(g/t);activeCells.add(`${n},${o}`)}console.log(activeCells),centerSeed()}function centerSeed(){let e=Array.from(activeCells).map(e=>Number(e.split(',')[0])),t=Array.from(activeCells).map(e=>Number(e.split(',')[1]));svgConfig.viewBox.x+=(Math.max(...e)-Math.min(...e)+1)*20,svgConfig.viewBox.y+=(Math.max(...t)-Math.min(...t)+1)*20}function updateSVGData(){svgConfig.cells=Array.from(activeCells).map(e=>{let[t,i]=e.split(',').map(Number);return{x:20*t,y:20*i,width:20,height:20}})}function updateGridData(){let{x:e,y:t,width:i,height:g}=svgConfig.viewBox,n=20*Math.floor(e/20),o=20*Math.ceil((e+i)/20),s=20*Math.floor(t/20),a=20*Math.ceil((t+g)/20);svgConfig.gridLines=[];for(let r=n;r<=o;r+=20)svgConfig.gridLines.push({x1:r,y1:s,x2:r,y2:a});for(let l=s;l<=a;l+=20)svgConfig.gridLines.push({x1:n,y1:l,x2:o,y2:l})}function renderSVG(){let e='http://www.w3.org/2000/svg',t=document.createElementNS(e,'svg');t.setAttribute('width',svgConfig.width),t.setAttribute('height',svgConfig.height),t.setAttribute('viewBox',`${svgConfig.viewBox.x} ${svgConfig.viewBox.y} ${svgConfig.viewBox.width} ${svgConfig.viewBox.height}`),t.style.backgroundColor='white';let i=document.createElementNS(e,'g');svgConfig.gridLines.forEach(t=>{let g=document.createElementNS(e,'line');g.setAttribute('x1',t.x1),g.setAttribute('y1',t.y1),g.setAttribute('x2',t.x2),g.setAttribute('y2',t.y2),g.setAttribute('stroke','#ccc'),g.setAttribute('stroke-width','0.5'),i.appendChild(g)}),t.appendChild(i);let g=document.createElementNS(e,'g');svgConfig.cells.forEach(t=>{let i=document.createElementNS(e,'rect');i.setAttribute('x',t.x),i.setAttribute('y',t.y),i.setAttribute('width',t.width),i.setAttribute('height',t.height),i.setAttribute('fill','black'),g.appendChild(i)}),t.appendChild(g),document.body.innerHTML='',document.body.appendChild(t),t.addEventListener('mousedown',e=>{0===e.button&&(isDragging=!0,dragStart={x:e.clientX,y:e.clientY},viewBoxStart={...svgConfig.viewBox})}),t.addEventListener('mousemove',e=>{if(isDragging){let t=(e.clientX-dragStart.x)*(svgConfig.viewBox.width/svgConfig.width),i=(e.clientY-dragStart.y)*(svgConfig.viewBox.height/svgConfig.height);svgConfig.viewBox.x=viewBoxStart.x-t,svgConfig.viewBox.y=viewBoxStart.y-i,updateGridData(),renderSVG()}}),t.addEventListener('mouseup',()=>isDragging=!1),t.addEventListener('mouseleave',()=>isDragging=!1),t.addEventListener('wheel',e=>{e.preventDefault();let t=e.deltaY>0?1.1:.9,i=e.clientX,g=e.clientY,n=i/svgConfig.width*svgConfig.viewBox.width+svgConfig.viewBox.x,o=g/svgConfig.height*svgConfig.viewBox.height+svgConfig.viewBox.y;svgConfig.viewBox.width*=t,svgConfig.viewBox.height*=t,svgConfig.viewBox.x=n-i/svgConfig.width*svgConfig.viewBox.width,svgConfig.viewBox.y=o-g/svgConfig.height*svgConfig.viewBox.height,updateGridData(),renderSVG()})}function animate(){nextGeneration(),updateSVGData(),updateGridData(),renderSVG(),setTimeout(animate,200)}const exampleBytes=[",
//                "16,8,56",
//                "],lineLength=8;decodeSeed(exampleBytes,8),updateGridData(),animate();</script></body></html>"
//        ));
        }

}

