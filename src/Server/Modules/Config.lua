-- Secrets (API keys, webhook URLs) are NOT stored in this file.
-- Copy config/Secrets.example.lua to src/Server/Modules/Secrets.lua and fill it in.
-- Secrets.lua is git-ignored. If it is missing, placeholder values are used and
-- external data / webhook calls will fail gracefully.
local Secrets do
	local ok, result = pcall(function()
		return require(script.Parent:FindFirstChild("Secrets"))
	end)
	if ok and type(result) == "table" then
		Secrets = result
	else
		warn("[Config] Secrets module not found - using placeholder values.")
		Secrets = {
			DataServerBaseUrl = "https://example.invalid/api/",
			ApiKeys = { player_data = "", moderation_data = "", flight_data = "" },
			Webhooks = { Moderation = "", Logs = "" },
		}
	end
end

local Configuration = {
	
	DataServers = {
		["player_data"] = {
			["url"] = Secrets.DataServerBaseUrl .. "playerdata/",
			["apiKey"] = Secrets.ApiKeys.player_data
		},
		["moderation_data"] = {
			["url"] = Secrets.DataServerBaseUrl .. "moderation/",
			["apiKey"] = Secrets.ApiKeys.moderation_data
		},
		["flight_data"] = {
			["url"] = Secrets.DataServerBaseUrl .. "flights/",
			["apiKey"] = Secrets.ApiKeys.flight_data
		}
	},

	AirportCode = "CODE",

	Arrival = "ArrivalAirport",
	Departure = "DestAirport",

	Version = "1.1.0",

	BetaOnlyAccess = true,
	BetaDefaultPermission = "Passenger",

	TestingMode = false,

	GroupInfo = {
		["GroupId"] = 9169280,
		["LogisticsGroupId"] = 32986839
	},
	
	Classes = {
		["Executive"] = {
			classLevel = 4, -- (higher level, better the class, keep classes above 0 level)
			groupRanks = {},
			shirtId = 5701078293,
			milesPrice = 2000,
			devProducts = { -- amountOfTickets = assetId (max 5 tickets)
				[1] = 0, -- all asset ids must be different for each class.
				[2] = 0,
				[3] = 0,
				[4] = 0,
				[5] = 1203797752
			},
			toolName = "Executive",
			milesMultiplier = 1.5
		},
		["Premium"] = {
			classLevel = 3,
			groupRanks = {},
			shirtId = 5701078293,
			milesPrice = 1150,
			devProducts = {

			},
			toolName = "Premium",
			milesMultiplier = 1.25
		},
		["Standard+"] = {
			classLevel = 2,
			groupRanks = {},
			shirtId = 5701078293,
			milesPrice = 600,
			devProducts = {

			},
			toolName = "Standard",
			milesMultiplier = 1.1
		},
		["Standard"] = {
			classLevel = 1,
			groupRanks = {},
			shirtId = 0,
			milesPrice = 0,
			devProducts = {
				
			},
			toolName = "Standard+",
			milesMultiplier = 1
		},
	},
	
	Permissions = {
		["Owner"] = {
			permLevel = 6,
			groupBounds = {{240, 255}}, -- Dual bound system {{10,20},{40,50},{30,20}}
			milesMultiplier = 2
		},
		["Admin"] = {
			permLevel = 5,
			groupBounds = {{200, 230}},
			milesMultiplier = 1.75
		},
		["Moderator"] = {
			permLevel = 4,
			groupBounds = {} -- Given manually to staff.
		},
		["Developer"] = {
			permLevel = 3,
			groupBounds = {{190, 195}},
			milesMultiplier = 1.75
		},
		["Staff"] = {
			permLevel = 2,
			groupBounds = {{60, 190}},
			milesMultiplier = 1.5
		},
		["Trainee"] = {
			permLevel = 1,
			groupBounds = {{50, 50}},
			milesMultiplier = 1
		},
		["Passenger"] = {
			permLevel = 0,
			groupBounds = {{0, 255}},
			milesMultiplier = 1
		}
	},

	Teams = {"Captain", "First Officer", "Airport Operations", "Customer Liaison", "Passenger"},
	
	StaffLock = {
		["DefaultMode"] = "HR", -- Only lets the level and greater have access to the game.
		["LowestStaffLevel"] = 3, -- Lowest level a player has to be to not be kicked via the kick-non-staff function.
		["Modes"] = {
			["HR"] = {
				groupBounds = {{200, 255}}, -- Dual group-bound system
				level = 4 -- Higher than restricted mode = Won't get kicked. 
			},
			["Staff"] = {
				groupBounds = {{60, 190}}, -- Allow devs cuz why not
				level = 3
			},
			["Trainee"] = {
				groupBounds = {{50, 50}},
				level = 2
			},
			["Passenger"] = {
				groupBounds = {{0, 30}},
				level = 1
			}
		}
	},

	
	
	Aircrafts = {
		["737-800"] = {
			["InsertId"] = 2541300077,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZECL",
					["Name"] = "Charles Lindbergh",
					["Summary"] = "AVIATION ICON - Charles Lindbergh is most well known for being an American Aviator, with one of his most notable achievements being the first person to complete a nonestop flight between New York City to Paris in 1927. He also won several awards for his achievements in Aviation and Military, earning a Distinguished Flying Cross, Legion of Honour and a Congressional Gold Medal."
				},
				[2] = {
					["RegCode"] = "G-ZEOW",
					["Name"] = "Orville Wright",
					["Summary"] = "AVIATION ICON - Alongside his brother, Wilbur Wright, the pair were pioneers in American Aviation, being recognised and credited as the first people to create a successful motor-operated airplane in 1903, spanning the start of decades of evolution and creating an entirely new industry of aviation. Collectively, the Wright Brothers have earned themselves the name of the fathers of aviation. "
				},
				[3] = {
					["RegCode"] = "G-ZEWW",
					["Name"] = "Wilbur Wright",
					["Summary"] = "AVIATION ICON - Alongside his brother, Orville Wright, the pair were pioneers in American Aviation, being recognised and credited as the first people to create a successful motor-operated airplane in 1903, spanning the start of decades of evolution and creating an entirely new industry of aviation. Collectively, the Wright Brothers have earned themselves the name of the fathers of aviation. "
				},
				[4] = {
					["RegCode"] = "G-ZEWC",
					["Name"] = "Sir William Churchill",
					["Summary"] = "BRITISH ICON - Churchill was a British statesman, soldier and writer who served as Prime Minister of the United Kingdom during World War II. He is also credited for ralling the British People to victory in World War II, and also won awards for his writing, such as winning a Nobel Prize in Literature in 1953. These achievements would ultimately mark Winston Churchill as one of the most recognisable British Prime Ministers."
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		["737 Max 8"] = {
			["InsertId"] = 0,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZENA",
					["Name"] = "Neil Armstrong",
					["Summary"] = "AVIATION ICON - Niel Armstrong is most known for being the first man on the moon. His links to aviation come through his careers as an aeronautical engineer, naval aviator and test pilot. partaking in the space missions of Apollo 11 and Gemini 8. Niel alongside Buzz Aldrin landed on the moon on the 20th July 1969, marking the end of the space race between the USA and Russia."
				},
				[2] = {
					["RegCode"] = "G-ZEAB",
					["Name"] = "Arthur Brown",
					["Summary"] = "BRITISH ICON - Arthur Brown is most well known for being an English rock singer, known for his flamboyant and theatrical performances. Known also  as the Godfather of Shock Rock, Arthur mostly made his fame through his rock group, The Crazy World of Arthur Brown. Some of his most well known songs include Build Me Up Buttercup & Fire."
				},
				[3] = {
					["RegCode"] = "G-ZEHH",
					["Name"] = "Howard Hughes",
					["Summary"] = "AVIATION ICON - Known also for his wealth, Howard Hughes is also famous for his successes in manufacturing and aviation, with his company building notable planes such as the Spurce Goose. He was also a director of movies, such as Hell’s Angels and The Outlaw. Howard also broke the world record for flying a plane over land, travelling at 352mph over Santa Ana, California in 1935."
				},
				[4] = {
					["RegCode"] = "G-ZEJC",
					["Name"] = "Jacqueline Cochran",
					["Summary"] = "AVIATION ICON - Jackqueline was an American pilot, and pioneered women’s aviation as one of the most prominent racing pilots of her generation. Out of her collection of records, Jacqueline is most well known for being the first woman to fly faster than the speed of sound on the 18th May 1953, and held more records for speed, altitude and distance than any other pilot at the time of her death in 1980."
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		["A320"] = {
			["InsertId"] = 0,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZEAE",
					["Name"] = "Amelia Earheart",
					["Summary"] = "AVIATION ICON - Being the first female aviator to cross the Atlantic Ocean on her own, Amerlia Earnheart made her mark on aviation through her achievements. Ultimately, her interest in aviation would also lead to her disappearance, when she went missing somewhere over the Pacific in July 1937 in an attemptto circumnavigate the globe, with her planes wreckage never being found."
				},
				[2] = {
					["RegCode"] = "G-ZERD",
					["Name"] = "Roald Dahl",
					["Summary"] = "BRITISH ICON - Roald Dahl was a British novelist, famous for his childrens poems and short stories. Some of his most famous work includes Matilda, Charlie and the Chocolate Factory and The BFG. He has sold over 250 million copies of his books worldwide and is recognised as one of the greatest storytellers for children in the entirety of the 20th century."
				},
				[3] = {
					["RegCode"] = "G-ZECC",
					["Name"] = "Clyde Cessna",
					["Summary"] = "AVIATION ICON - Clyde Cessna was an American aircraft designer, who is well known for his innovations in aviation. His fame mainly comes from being the founder of the American plane manufacturer, Cessna, which he created in 1927. Cesnna now has several successful aircrafts that it manufacturers, such as the Cessna 172 and the Citation family of planes."
				},
				[4] = {
					["RegCode"] = "G-ZEJD",
					["Name"] = "Jimmy Doolittle",
					["Summary"] = "AVIATION ICON - Jimmy was an Amerrican military general, known mainly for his pioneers in aviation. During his career as a military general, he recieved the Medal of Honour for his daring raid on Japan in World War II. In addition, Jimmy also made early coast-to-coast flights, record-breaking speed flights and won multiple flying races, marking him as a famous aviator."
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		--[[
		["A320 NEO (Special Livery)"] = {
			["InsertId"] = 0,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZETM",
					["Name"] = "Sir Tom Moore",
					["Summary"] = "BRITISH ICON - Sir Tom Moore became famous for his fundraising efforts during the COVID-19 pandemic in 2020. Serving previously as an British Army officer, Tom managed to raise a staggering £32.8 million for the NHS by walkin around his garden in the run up to his 100th birthday. Tom has also received a number of awards, including the Pride of Britain Award and the Yorkshire Regiment Medal."
				},
				[2] = {
					["RegCode"] = "G-ZEDD",
					["Name"] = "Donald Douglas",
					["Summary"] = "AVIATION ICON - Donald Wills Douglas was an iconic aviation pioneer who designed and built the Douglas Cloudster, the fist airplane that flew across the United States with a payload greater than its own weight. Ultimately, Donald would go on to found the Douglas Aircraft company, which was famous for its Douglas DC family of planes and would also help to provide planes during World War II."
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		--]]
		["A321"] = {
			["InsertId"] = 0,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZEBC",
					["Name"] = "Bessie Coleman",
					["Summary"] = "AVIATION ICON - Bessie was  an early American civil aviator. She became the first African-American woman and first native American to hold a pilot licence. She would then go on to become the first black woman to earn an international pilot’s licence in 1921. Bessie ultimately led efforts of diversity in aviation, and would also become famous for her flying stunts and ariel tricks. "
				},
				[2] = {
					["RegCode"] = "G-ZEWS",
					["Name"] = "William Shakespeare",
					["Summary"] = "BRITISH ICON - William Shakespear was a famous British writer, who is known worldwide for his creation of recognisable stories such as Romeo & Juliet alongside Hamlet. Shakespear was selected for this plane due to his influence on British culture and writing in general. With him also being born in Stratford-Upon-Avon in the United Kingdom, he is a great representative for our home country. "
				},
				[3] = {
					["RegCode"] = "G-ZEHK",
					["Name"] = "Herb Kelleher",
					["Summary"] = "AVIATION ICON - Keller was an American Businessman and lawyer, being most famous for co-founding the American Airline, Southwest Airlines, in 1967. Keller would later become the CEO of Southwest, growing the company from just 3 jets to the country’s largest low-fare carrier. Southwest now has 121 destinations within the United States, and operates to 10 additional countries."
				},
				[4] = {
					["RegCode"] = "G-ZEEJ",
					["Name"] = "Sir Elton John",
					["Summary"] = "BRITISH ICON - Born in 1947, Elton John is most well known for being a singer, pianist and composer. Commonly nicknamed the ‘Rocket Man’ after his 1972 hit single of the same name, Elton has created several iconic tracks during his career, such as Crocodile Rock and most recently Cold Heart. He has released a total of 31 albums since 1969, being one of the most successful solo artists of all time."
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		--[[
		["A321 NEO (Special Livery)"] = {
			["InsertId"] = 0,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZESR",
					["Name"] = "Sally Ride",
					["Summary"] = "AVIATION ICON - Sally Ride is famous for being an American astronaut, who was in the first group of astronauts that included woman. She became the first American woman in space on the STS-7 space shuttle mission, and founded her own company named Sally Ride Science as an initiative to encourage girls to be interested in science, technology, engineering and maths, further diversifying the industry as a whole. "
				},
				[2] = {
					["RegCode"] = "G-ZEPD",
					["Name"] = "Princess Diana",
					["Summary"] = "BRITISH ICON - Princess Diana was a member of the British Royal Family, known as being the wife of Charles and the Princess of Wales. She was best known for her charitable work and style. Diana ultimately died at a young age after a tragic car accident in 1997 when she was trying to escape the press, being later buried in September of the same year."
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		--]]
		["777-300ER"] = {
			["InsertId"] = 10485952019,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZEJL",
					["Name"] = "John Lennon",
					["Summary"] = "BRITISH ICON - John Lennon was an English singer, songwriter, musician and peace  activist, who aclaimed most of his fame for being one of the members of the famous British band, The Beatles. Some of his most famous songs include Here Comes the Sun and Hey Jude. John was ultimately assassinated in 1980 on a trip to New York, with a large amount of speculation around his death."
				},
				[2] = {
					["RegCode"] = "G-ZEQE",
					["Name"] = "Queen Elizabeth II",
					["Summary"] = "BRITISH ICON - Known formally as Elizabeth Alexandra Mary Windsor, Elizabeth II is the Queen of the United Kingdom and 14 other Commonwealth realms. She is the forefront of the British Royal Family, and has famously broken records for her length of service as the Queen, recently celebrating her Platinum Jubilee in 2022 for 70 years of service. "
				},
				[3] = {
					["RegCode"] = "G-ZEIN",
					["Name"] = "Sir Isaac Newton",
					["Summary"] = "BRITISH ICON - Newton was a English mathmeician, physicist, astronomer, alchemist, theologian and author, being widely recognised for his efforts in maths and physics. Most famously of all, Newton is credited for the discovery of gravity, changing the way that we understand the universe by creating the laws of gravity and motion, and later inventing calculus."
				},
				[4] = {
					["RegCode"] = "G-ZECD",
					["Name"] = "Charles Darwin",
					["Summary"] = "BRITISH ICON - Darwin was an English naturalist, geologist and biologist, known best for his contributions to evolutionary biology. He is credited for creating the Theory of Evolution, of which it proposes that all species oflife have descended from a common ancestor, which is now widely accepted and considered a fundamental concept of Science."
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		--[[
		["777-300ER (Special Livery)"] = {
			["InsertId"] = 0,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZEWB",
					["Name"] = "William Boeing",
					["Summary"] = "AVIATION ICON - William Edward Boeing was an American aviation pioneer who founded the Pacific Airplane Company in 1916, which would be renamed to Boeing a year later. Boeing are famous for their wide offering of commercial aircraft, such as the 737, 787 and 777, the very plane you’re on now! Boeing is now the largest exporter in the United States by dollar value, and one of the biggest aircraft manufacturers."
				},
				[2] = {
					["RegCode"] = "G-ZEAT",
					["Name"] = "Alan Turing",
					["Summary"] = "BRITISH ICON - Alan Turnin was an English mathmatician and computer scientist. Turning is highly credited for the development  of theoretical computer science, providing formalisation of the concepts of algorithm and computation with the Turning machine. He would later go onto solve the halting problem, and have a great influence with the Enigma machine during World War II."
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		--]]
		["A350-1000"] = {
			["InsertId"] = 0,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZERB",
					["Name"] = "Sir Richard Branson",
					["Summary"] = "AVIATION ICON - Richard is a British entrepreneur, famous for founding the Virgin Group in 1970. This group now controls over 400 companies in various fields, including aviation with both Virgin Atlantic and Virgin Australia. The company is now also expanding to spaceflight with Virgin Galactic and other innotive industries, such the Virgin Hyperloop."
				},
				[2] = {
					["RegCode"] = "G-ZEAF",
					["Name"] = "Sir Alexander Fleming",
					["Summary"] = "BRITISH ICON - Alexander Fleming wasa Scottish physician and microbiologist who is best known for discovering the world’s first broadly effective antibiotic substance, Penicillin. Interestingly, Fleming discovered this by accident after finding mold on some bacteria. Fleming’s efforts would ultimately be the start of revolutionary advancements in both Science and Medicine which allowed for the development of modern medicines."
				},
				[3] = {
					["RegCode"] = "G-ZEBA",
					["Name"] = "Buzz Aldrin",
					["Summary"] = "AVIATION ICON - Buzz is a former American astronaut, engineer and fighter pilot. He is most famous for being on Apollo 11, which was the first space mission to have humans land and walk on the moon, which he would complete alongside the mission commander Neil Armstrong. Buzz also pilotted the Gemini 12 mission, completing 3 spacewalks during this."
				},
				[4] = {
					["RegCode"] = "G-ZEOL",
					["Name"] = "Otto Lilienthal",
					["Summary"] = "AVIATION ICON - Otto was a German Aviator, who became known as the “flying man”. He was the first person to make a well-documented, repeated, successful flights with gliders. His work would ultimately lead him to developing the concept of the modern wing, with his attempts at flight in 1891 being seen as the beginning of human flight. He is also sometimes referred to as the “father of aviation”."
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		--[[
		["A350-1000 (Special Livery)"] = {
			["InsertId"] = 0,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZESH",
					["Name"] = "Stephen Hawking",
					["Summary"] = "BRITISH ICON - Stephen Hawking was an English theoretical physicist, cosmologist and author. His work on the origins and structure of the universe revolutionalised the theoretical physicist field. His books have appealed to readers who don’t have the same scientific background as Hawking’s, and his triumphs despite his disabilities."
				},
				[2] = {
					["RegCode"] = "G-ZEPP",
					["Name"] = "Prince Phillip",
					["Summary"] = "BRITISH ICON - The husband to Queen Elizabeth II, Prince Philip was also known as the Duke Of Edinburrgh. He was the consort of the British monarchy since Elizabeth’s accessionas Queen in 1952 until his death in 2021, making him the longest-serving royal consort in history. "
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		--]]
		["787 Dreamliner"] = {
			["InsertId"] = 0,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZEDB",
					["Name"] = "David Bowie",
					["Summary"] = "BRITISH ICON - Also known as David Robert Jones, David Bowie was an English singer-songwriter and actor. He was a leading figure in the music industry, and is often regarded as one of the most influential musicians of the 20th century. He is famous for his songs, such as Space Oddity and Hero, and also colleaberated with the British band Queen to make Under Pressure. "
				},
				[2] = {
					["RegCode"] = "G-ZEAJ",
					["Name"] = "Amy Johnson",
					["Summary"] = "AVIATION ICON - Amy Johnson was a pioneering English pilot who was the first woman to fly solo from London to Australia. After receiving her pilot licnece in 1929, she began her Journey to Australia, which would span a period of 19 days. She completed this triumph on the 26th May 1930. She also completed numerous journeys as a female pilot, and earned in Serave Tropy award in 1932."
				},
				[3] = {
					["RegCode"] = "G-ZEPR",
					["Name"] = "Paul Ritter",
					["Summary"] = "BRITISH ICON - Otherwise known as Simon Paul Adams, Paul Ritter was an iconic English actor in famous British TV shows such as Chernobyl and most famously Friday Night Dinner. He also acted in movies including Harry Pottor and the Half-Blood Prince and Son of Rambow. Paul unfortunately died in mid 2021 of a Brain Tumour, aged just 54. This plane was named in his honour to British culture. "
				},
				[4] = {
					["RegCode"] = "G-ZEFF",
					["Name"] = "Freddie Mercury",
					["Summary"] = "BRITISH ICON - Freddie was a British Singer and songwriter, who achieved worldwide fame as the lead vocalist of the rock band Queen. He was regarded as one of the greatest singers in the history of rock music, and created iconic songs such as Bohemian Rhapsody, We Will Rock You and Don’t Stop Me Now. He was also known for his flamboyant stage persona and four-octave vocal range."
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		--[[
		["787 Dreamliner (Special Livery)"] = {
			["InsertId"] = 0,
			["Names"] = {
				[1] = {
					["RegCode"] = "G-ZEDA",
					["Name"] = "Sir David Attenborough",
					["Summary"] = "BRITISH ICON - David Attenborough is an English broadcaster, biologist, natural historian and author. He is most well known for his presenting, specifically with animal shows such as The Blue Planet and Natural World. He is also known for his written work, such as his ‘A Life on Our Planet’ book, and has won a large range of awards for his efforts. "
				},
				[2] = {
					["RegCode"] = "G-ZETB",
					["Name"] = "Sir Tim Berners-Lee",
					["Summary"] = "BRITISH ICON - Tim is a English computer scientist, most famous for being the inventor of the World Wide Web. Although the web was originally conceived and developed  o meet the demand for automated information-sharing between scientists, it has now spanned into an array of industries and millions of sites. Tim now stands as the Founding Director of the World Wide Web Foundation."
				}
			},
			["Classes"] = {
				["Executive"] = 5, -- ClassName = TotalBookings
				["Premium"] = 8,
				["Standard+"] = 10,
				["Standard"] = 20
			}
		},
		--]]
	},

	Webhooks = {
		["Moderation"] = Secrets.Webhooks.Moderation,
		["Logs"] = Secrets.Webhooks.Logs
	},

	Moderation = {
		Immune = {171789275}
	},

	Uniform = {
		["Customer Liaison"] = {
			["Singular"] = false,
			["Variants"] = {
				["Male"] = {
					["ShirtId"] = 9506208657,
					["PantsId"] = 9506211017
				},
				["Female"] = {
					["ShirtId"] = 9497702256,
					["PantsId"] = 9497707000
				}
			}
		},
		["Captain"] = {
			["Singular"] = true,
			["Variant"] = {
				["ShirtId"] = 9497733581,
				["PantsId"] = 9480618618
			}
		},
		["First Officer"] = {
			["Singular"] = true,
			["Variant"] = {
				["ShirtId"] = 14341259565,
				["PantsId"] = 14341259540
			}
		},
		["Airport Operations"] = {
			["Singular"] = true,
			["Variant"] = {
				["ShirtId"] = 9497859906,
				["PantsId"] = 9497785814
			}
		}
	},

	["SuitcaseThemes"] = {
		["Chequered-Striped"] = 1289685686,
		["Barbershop"] = 1289685686,
		["Brick"] = 1289685686,
		["Chequered"] = 1289685686,
		["Y-Design"] = 1289685686,
		["Wooden"] = 1289685686,
		["Triangles"] = 1289685686,
		["Roadways"] = 1289685686,
		["Arrows"] = 1289685686,
		["Hexagon"] = 1289685686,
		["Striped"] = 1289685686,
		["Split Stiped"] = 1289685686
	}
}

return Configuration