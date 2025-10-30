/**
 * seed.js
 *
 * File-level JSDoc:
 * Simple database seeding script that populates the Bike table using Prisma.
 * It creates a few example bike records (upsert by numeric id) so the app has
 * reasonable default data for development or demo environments.
 *
 * The script constructs an array of bike objects, then upserts each into the
 * database using PrismaClient. After finishing it disconnects the Prisma client.
 */

const {PrismaClient} = require("@prisma/client");
const prisma = new PrismaClient();

/**
 * Main seeding routine.
 *
 * Creates a small set of example bikes and upserts them into the Bike table.
 * Uses the index in the array + 1 as the upsert lookup id so repeated runs are
 * idempotent for these fixed entries.
 */
async function main() {
    const bikes = [
        { name: "YZF-R6", brand: "Yamaha", category: "Supersport" },
        { name: "CBR600RR", brand: "Honda", category: "Supersport" },
        { name: "GSX-R600", brand: "Suzuki", category: "Supersport" },
        { name: "ZX-6R", brand: "Kawasaki", category: "Supersport" },
        { name: "Panigale V2", brand: "Ducati", category: "Supersport" }
    ];

    for (const b of bikes) {
        await prisma.bike.upsert({
            where: { id: bikes.indexOf(b) + 1 },
            update: {},
            create: b
        });
    }

    console.log("Seeded bikes.");
}

/**
 * Execute main and ensure the Prisma client disconnects when finished.
 */
main().finally(() => prisma.$disconnect());