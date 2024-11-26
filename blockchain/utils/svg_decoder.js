const atob = require("atob");
const fs = require("fs");

function decodeBase64(data) {
    const base64Data = data.split(",")[1]; // Remove the "data:application/json;base64," prefix
    const jsonMetadata = JSON.parse(atob(base64Data));
    fs.writeFileSync("data.json", JSON.stringify(jsonMetadata, null, 2));
    const image_svg = atob(jsonMetadata.image.split(",")[1]);
    fs.writeFileSync("image.svg", image_svg);
    const animated_img_svg = atob(jsonMetadata.animation_url.split(",")[1]);
    fs.writeFileSync("animated.html", animated_img_svg);
}

// Replace this with the tokenURI result
module.exports = decodeBase64;
