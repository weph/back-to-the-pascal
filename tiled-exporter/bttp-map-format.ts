/// <reference types="@mapeditor/tiled-api" />

const mapFormat = {
    name: 'BTTP map format',
    extension: 'map',

    write: function (map: TileMap, fileName: string): string | undefined {
        tiled.log(`Exporting map of size ${map.width}x${map.height}`)

        let numTiles = 0
        const tileMapping = new Map<number, number>
        tileMapping.set(-1, 0)

        const groundLayer = map.layers[0] as TileLayer

        const boundingRect = groundLayer.region().boundingRect

        const startX = boundingRect.x
        const endX = boundingRect.x + boundingRect.width
        const startY = boundingRect.y
        const endY = boundingRect.y + boundingRect.height

        const mapData = []
        for (const layer of map.layers) {
            const tileLayer = layer as TileLayer

            tiled.log(`Exporting layer ${tileLayer.name} of size ${boundingRect.width}x${boundingRect.height}`)

            for (let y = startY; y < endY; y++) {
                for (let x = startX; x < endX; x++) {
                    const tileId = tileLayer.cellAt(x, y).tileId

                    if (!tileMapping.has(tileId)) {
                        tileMapping.set(tileId, ++numTiles)
                    }

                    mapData.push(tileMapping.get(tileId))
                }
            }
        }

        const data = []

        data.push(boundingRect.width)
        data.push(boundingRect.height)
        data.push(map.layerCount)
        data.push(tileMapping.size - 1)

        tileMapping.forEach((v, k) => {
            if (k === -1) {
                return
            }

            data.push(map.tilesets[0].tile(k).property('walkable') ?? false)
        })

        data.push(...mapData)

        tiled.log(data.join(', '))

        const file = new BinaryFile(fileName, BinaryFile.WriteOnly)
        file.write(Uint8Array.from(data).buffer)
        file.commit()

        tiled.log(`Using tileset ${map.tilesets[0].imageFileName}`)
        const tilesetImage = new Image(map.tilesets[0].imageFileName)
        const colorTable = tilesetImage.colorTable()

        // @ts-ignore
        const resultImage = new Image(320, 200, tilesetImage.format)
        resultImage.setColorTable(colorTable)
        resultImage.fill(0)

        let currentX = 0
        let currentY = 0
        tileMapping.forEach((v, k) => {
            if (k === -1) {
                return
            }

            const tile = map.tilesets[0].tile(k)
            const imageRect = tile.imageRect

            for (let tx = 0; tx < imageRect.width; tx++) {
                for (let ty = 0; ty < imageRect.height; ty++) {
                    const index = colorTable.indexOf(tilesetImage.pixel(imageRect.x + tx, imageRect.y + ty))
                    resultImage.setPixel(currentX + tx, currentY + ty, index)
                }
            }

            currentX += 16
            if (currentX >= 320) {
                currentX = 0
                currentY += 16
            }
        })

        resultImage.save(`${fileName}.png`)

        return undefined
    }
}

tiled.registerMapFormat('bttp', mapFormat)