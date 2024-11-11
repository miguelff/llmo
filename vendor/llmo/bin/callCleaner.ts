#!/usr/bin/env node

import create from '../src/context'
import { Cleaner } from '../src/steps/cleaner'

const input = {
    topics: [
        {
            name: 'Volvo XC40',
            urls: [
                'https://www.volvocars.com/es/cars/xc40/',
                'https://www.euroncap.com/en/results/volvo/xc40/34945',
            ],
            sentiments: [4, 5, 5],
        },
        {
            name: 'Toyota Corolla',
            urls: ['https://www.toyota.es/'],
            sentiments: [4, 5],
        },
        {
            name: 'Mazda 3',
            urls: ['https://www.mazda.es/'],
            sentiments: [4, 4],
        },
        {
            name: 'Volkswagen Golf',
            urls: ['https://www.volkswagen.es/'],
            sentiments: [4, 5],
        },
        {
            name: 'Euro NCAP',
            urls: ['https://www.euroncap.com'],
            sentiments: [3],
        },
        {
            name: 'Mazda CX-5',
            urls: [
                'https://www.mazda.es/modelos/mazda-cx-5/',
                'https://www.coches.net/nuevo-mazda-cx-5-presentacion',
            ],
            sentiments: [5, 4],
        },
        {
            name: 'Toyota RAV4',
            urls: [
                'https://www.toyota.es/coches/rav4/',
                'https://www.euroncap.com/en/results/toyota/rav4/34873',
            ],
            sentiments: [5, 5],
        },
        {
            name: 'Hyundai Tucson',
            urls: [
                'https://www.hyundai.es/tucson/',
                'https://www.hyundai.com/es/es/',
            ],
            sentiments: [5, 4],
        },
        {
            name: 'Kia Sportage',
            urls: [
                'https://www.kia.com/es/modelos/sportage/',
                'https://www.kia.com/es/',
            ],
            sentiments: [5, 4],
        },
        {
            name: 'Volkswagen Tiguan',
            urls: ['https://www.volkswagen.es/es/modelos/tiguan.html'],
            sentiments: [5],
        },
        {
            name: 'Skoda Octavia',
            urls: ['https://www.skoda.es/'],
            sentiments: [4],
        },
        {
            name: 'Volvo',
            urls: [],
            sentiments: [5],
        },
        {
            name: 'Toyota',
            urls: [],
            sentiments: [5],
        },
        {
            name: 'Mazda',
            urls: [],
            sentiments: [5],
        },
        {
            name: 'Subaru',
            urls: [],
            sentiments: [4],
        },
        {
            name: 'Volkswagen',
            urls: [],
            sentiments: [4],
        },
        {
            name: 'Hyundai',
            urls: [],
            sentiments: [4],
        },
        {
            name: 'BMW Serie 3',
            urls: ['https://www.km77.com/coches/bmw/serie-3'],
            sentiments: [4],
        },
        {
            name: 'Audi Q3',
            urls: ['https://www.motor.es/audi/q3'],
            sentiments: [4],
        },
    ],
    urls: {
        'www.autobild.es': ['https://www.autobild.es/'],
        'www.motorpasion.com': ['https://www.motorpasion.com/'],
        'www.euroncap.com': [
            'https://www.euroncap.com',
            'https://www.euroncap.com/en/results/volvo/xc40/34945',
            'https://www.euroncap.com/en/results/toyota/rav4/34873',
        ],
        'www.volvocars.com': ['https://www.volvocars.com/es/cars/xc40/'],
        'www.mazda.es': [
            'https://www.mazda.es/modelos/mazda-cx-5/',
            'https://www.mazda.es/',
        ],
        'www.toyota.es': [
            'https://www.toyota.es/coches/rav4/',
            'https://www.toyota.es/',
        ],
        'www.hyundai.es': ['https://www.hyundai.es/tucson/'],
        'www.kia.com': [
            'https://www.kia.com/es/modelos/sportage/',
            'https://www.kia.com/es/',
        ],
        'www.volkswagen.es': [
            'https://www.volkswagen.es/es/modelos/tiguan.html',
            'https://www.volkswagen.es/',
        ],
        'www.coches.net': [
            'https://www.coches.net/',
            'https://www.coches.net/nuevo-mazda-cx-5-presentacion',
        ],
        'www.hyundai.com': ['https://www.hyundai.com/es/es/'],
        'www.skoda.es': ['https://www.skoda.es/'],
        'www.km77.com': [
            'https://www.km77.com/',
            'https://www.km77.com/coches/bmw/serie-3',
        ],
        'www.motor.es': ['https://www.motor.es/audi/q3'],
    },
}

async function main() {
    const context = create()
    context.bag['query'] = 'coches baratos'
    const cleaner = new Cleaner(context)
    const result = await cleaner.execute(input)

    if (result.isOk()) {
        console.log('Cleaned results:', JSON.stringify(result.value, null, 2))
    } else {
        console.error('Error:', result.error)
    }
}

main().catch(console.error)
