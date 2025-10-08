const {PrismaClient} = require("@prisma/client");
const prisma = new PrismaClient();

async function main() {

// a few bikes to fill the bike table
    const bikes = [
        { name: "YZF-R6", brand: "Yamaha", category: "Supersport" },
        { name: "CBR600RR", brand: "Honda", category: "Supersport" },
        { name: "GSX-R600", brand: "Suzuki", category: "Supersport" },
        { name: "ZX-6R", brand: "Kawasaki", category: "Supersport" },
        { name: "Panigale V2", brand: "Ducati", category: "Supersport" }
    ];


    for (const b of bikes) {
        await prisma.bike.upsert({
            where: {id: bikes.indexOf(b) + 1},
            update: {},
            create: b
        });
    }

    console.log("Seeded bikes.");
}

main().finally(() => prisma.$disconnect());
