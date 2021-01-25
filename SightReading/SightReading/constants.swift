//
//  constants.swift
//  NewSightReading
//
//  Created by Zhang, Hongchao on 2021/1/19.
//

import Foundation
import UIKit

let photoCollectionWH: CGFloat = 128
let basicInfoKey = "basic info"
let tempoKey = "tempo"
let meterKey = "meter"
let barFramesKey = "bar frames"

let meterValues: [String] = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]

let tempoDisplaySymbols = ["Larghissimo",
                           "Grave",
                           "Lento",
                           "Largo",
                           "Larghetto",
                           "Adagio",
                           "Adagietto",
                           "Andante",
                           "Andante",
                           "Andantino",
                           "Marcia moderato",
                           "Moderato",
                           "Allegretto",
                           "Allegro",
                           "Vivace",
                           "Vivacissimo",
                           "Allegrissimo",
                           "Presto",
                           "Prestissimo"]

let tempoFullSymbols = ["Larghissimo － 极端地缓慢（10-19bpm）",
                    "Grave － 沉重的、严肃的（20-40bpm）",
                    "Lento － 缓板（41-45 bpm）",
                    "Largo － 最缓板（现代）或广板（46-50bpm）",
                    "Larghetto － 甚缓板（51-55bpm）",
                    "Adagio － 柔板 / 慢板（56-65 bpm）",
                    "Adagietto － 颇慢（66-69bpm）",
                    "Andante moderato -中慢板（70-72bpm）",
                    "Andante － 行板（73 - 77 bpm）",
                    "Andantino － 稍快的行板（78-83bpm）",
                    "Marcia moderato - 行进中（84-85bpm）",
                    "Moderato － 中板（86 - 97 bpm）",
                    "Allegretto － 稍快板（98-109bpm）（比 Allegro 较少见）",
                    "Allegro (Moderato) － 快板（110-132bpm）",
                    "Vivace － 活泼的快板（133-140 bpm）",
                    "Vivacissimo -非常快的快板(141-150bpm)",
                    "Allegrissimo -极快的快板(151-167bpm)",
                    "Presto － 急板（168 -177bpm）",
                    "Prestissimo － 最急板（178 - 500 bpm）"]

let tempoValues: [String: [String: Int]] = ["Larghissimo － 极端地缓慢（10-19bpm）": ["min": 10, "max":19, "value": 15],
                                            "Grave － 沉重的、严肃的（20-40bpm）": ["min": 20, "max":40, "value": 30],
                                            "Lento － 缓板（41-45 bpm）": ["min": 41, "max":45, "value": 43],
                                            "Largo － 最缓板（现代）或广板（46-50bpm）": ["min": 46, "max":50, "value": 48],
                                            "Larghetto － 甚缓板（51-55bpm）": ["min": 51, "max":55, "value": 53],
                                            "Adagio － 柔板 / 慢板（56-65 bpm）": ["min": 56, "max":65, "value": 60],
                                            "Adagietto － 颇慢（66-69bpm）": ["min": 66, "max":69, "value": 68],
                                            "Andante moderato -中慢板（70-72bpm）": ["min": 70, "max":72, "value": 71],
                                            "Andante － 行板（73 - 77 bpm）": ["min": 73, "max":77, "value": 75],
                                            "Andantino － 稍快的行板（78-83bpm）": ["min": 78, "max":83, "value": 80],
                                            "Marcia moderato - 行进中（84-85bpm）": ["min": 84, "max":85, "value": 85],
                                            "Moderato － 中板（86 - 97 bpm）": ["min": 86, "max":97, "value": 90],
                                            "Allegretto － 稍快板（98-109bpm）（比 Allegro 较少见）": ["min": 98, "max":109, "value": 105],
                                            "Allegro (Moderato) － 快板（110-132bpm）": ["min": 110, "max":132, "value": 120],
                                            "Vivace － 活泼的快板（133-140 bpm）": ["min": 133, "max":140, "value": 135],
                                            "Vivacissimo -非常快的快板(141-150bpm)": ["min": 141, "max":150, "value": 145],
                                            "Allegrissimo -极快的快板(151-167bpm)": ["min": 151, "max":167, "value": 160],
                                            "Presto － 急板（168 -177bpm）": ["min": 168, "max":177, "value": 170],
                                            "Prestissimo － 最急板（178 - 500 bpm）": ["min": 178, "max":500, "value": 200]]

