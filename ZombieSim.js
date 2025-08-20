

        window.onload = function() {


            // --- CONSTANTS AND VARIABLES ---


            const canvas = document.getElementById('gameCanvas');


            const ctx = canvas.getContext('2d');


            const startBtn = document.getElementById('startBtn');


            const resetBtn = document.getElementById('resetBtn');


            const zombieCountInput = document.getElementById('zombieCount');


            const personCountInput = document.getElementById('personCount');


            const policeCountInput = document.getElementById('policeCount');


            const personCountDisplay = document.getElementById('personCountDisplay');


            const zombieCountDisplay = document.getElementById('zombieCountDisplay');


            const policeCountDisplay = document.getElementById('policeCountDisplay');


            const cohesionRadiusInput = document.getElementById('cohesionRadius');


            const cohesionInstinctInput = document.getElementById('cohesionInstinct');


            const separationRadiusInput = document.getElementById('separationRadius');


            const separationInstinctInput = document.getElementById('separationInstinct');


            const alignmentRadiusInput = document.getElementById('alignmentRadius');


            const alignmentInstinctInput = document.getElementById('alignmentInstinct');


            const policeFireRateInput = document.getElementById('policeFireRate'); // New DOM element


            const policeImmunityToggle = document.getElementById('policeImmunityToggle'); // New DOM element


            const peopleFlockingToggle = document.getElementById('peopleFlockingToggle');


            const zombieFlockingToggle = document.getElementById('zombieFlockingToggle');


            const messageBox = document.getElementById('messageBox');


            const messageText = document.getElementById('messageText');


            const overlay = document.getElementById('overlay');


  


            // Set canvas dimensions


            canvas.width = 768; // 3:2 aspect ratio for a street-like feel


            canvas.height = 512;


  


            let entities = []; // Array to hold all people and zombies


            let buildings = []; // Array to hold all buildings


            let animationFrameId = null;


            let isRunning = false;


            let particles = []; // New array to hold the particle projectiles


  


            // Simulation parameters from sliders


            let cohesionRadius = parseFloat(cohesionRadiusInput.value);


            let cohesionInstinct = parseFloat(cohesionInstinctInput.value);


            let separationRadius = parseFloat(separationRadiusInput.value);


            let separationInstinct = parseFloat(separationInstinctInput.value);


            let alignmentRadius = parseFloat(alignmentRadiusInput.value);


            let alignmentInstinct = parseFloat(alignmentInstinctInput.value);


            let policeFireRate = parseFloat(policeFireRateInput.value); // New variable


            let policeImmunityEnabled = policeImmunityToggle.checked; // New variable


            let peopleFlockingEnabled = peopleFlockingToggle.checked;


            let zombieFlockingEnabled = zombieFlockingToggle.checked;


  


            // --- ENTITY CLASSES ---


            /**


             * Base class for all moving entities (people and zombies).


             */


            class Entity {


                constructor(x, y, size, speed, color) {


                    this.x = x;


                    this.y = y;


                    this.size = size;


                    this.speed = speed;


                    this.color = color;


                    this.dx = (Math.random() - 0.5) * speed;


                    this.dy = (Math.random() - 0.5) * speed;


                }


  


                /**


                 * Draws the entity on the canvas.


                 */


                draw() {


                    ctx.fillStyle = this.color;


                    ctx.beginPath();


                    ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);


                    ctx.fill();


                }


  


                /**


                 * Moves the entity, checking for wall collisions and implementing pathing.


                 */


                move() {


                    // Check for building collisions with a "look ahead"


                    let willCollide = false;


                    for (const building of buildings) {


                        if (this.checkBuildingCollision(building, this.x + this.dx, this.y + this.dy)) {


                            willCollide = true;


                            break;


                        }


                    }


  


                    if (willCollide) {


                        // Find a new, clear path by trying different angles


                        let currentAngle = Math.atan2(this.dy, this.dx);


                        // Try turning left, right, and reversing


                        const anglesToTry = [


                            currentAngle + Math.PI / 2, // Left turn


                            currentAngle - Math.PI / 2, // Right turn


                            currentAngle + Math.PI // Reverse direction


                        ];


                        let newDirectionFound = false;


                        for (const angle of anglesToTry) {


                            const testDx = Math.cos(angle) * this.speed;


                            const testDy = Math.sin(angle) * this.speed;


                            // Check if this new direction is clear


                            let testCollision = false;


                            for (const building of buildings) {


                                if (this.checkBuildingCollision(building, this.x + testDx, this.y + testDy)) {


                                    testCollision = true;


                                    break;


                                }


                            }


                            if (!testCollision) {


                                // A clear path was found, update velocity and exit


                                this.dx = testDx;


                                this.dy = testDy;


                                newDirectionFound = true;


                                break;


                            }


                        }


  


                        if (!newDirectionFound) {


                            // If no clear path was found (e.g., in a tight corner),


                            // try a full random direction change as a last resort


                            this.dx = (Math.random() - 0.5) * this.speed;


                            this.dy = (Math.random() - 0.5) * this.speed;


                        }


                    }


  


                    this.x += this.dx;


                    this.y += this.dy;


  


                    // Clamp position to prevent entities from leaving the canvas


                    if (this.x - this.size < 0) {


                        this.x = this.size;


                        this.dx = Math.abs(this.dx);


                    } else if (this.x + this.size > canvas.width) {


                        this.x = canvas.width - this.size;


                        this.dx = -Math.abs(this.dx);


                    }


  


                    if (this.y - this.size < 0) {


                        this.y = this.size;


                        this.dy = Math.abs(this.dy);


                    } else if (this.y + this.size > canvas.height) {


                        this.y = canvas.height - this.size;


                        this.dy = -Math.abs(this.dy);


                    }


                }


  


                /**


                 * Checks for collision with a building.


                 * @param {object} building - The building object to check against.


                 * @param {number} x - The entity's new x position.


                 * @param {number} y - The entity's new y position.


                 */


                checkBuildingCollision(building, x, y) {


                    const rectX = building.x;


                    const rectY = building.y;


                    const rectW = building.width;


                    const rectH = building.height;


                    const circleX = x;


                    const circleY = y;


                    const circleR = this.size;


  


                    // Find the closest point on the rectangle to the center of the circle


                    const closestX = Math.max(rectX, Math.min(circleX, rectX + rectW));


                    const closestY = Math.max(rectY, Math.min(circleY, rectY + rectH));


  


                    // Calculate the distance between the closest point and the circle's center


                    const distanceX = circleX - closestX;


                    const distanceY = circleY - closestY;


                    const distanceSquared = (distanceX * distanceX) + (distanceY * distanceY);


  


                    // If the distance is less than the radius, there's a collision


                    return distanceSquared < (circleR * circleR);


                }


            }


  


            /**


             * Represents an uninfected person.


             * Extends the base Entity class.


             */


            class Person extends Entity {


                constructor(x, y) {


                    // Changed color to light grey


                    super(x, y, 4, 1.5, '#cccccc');


                    this.type = 'person';


                    this.fleeSpeed = 1.5;


                    this.wanderSpeed = 0.5;


                    this.wanderTimer = 0;


                    this.wanderDuration = 120; // Frames to wander before a direction change


                }


  


                /**


                 * Person's movement logic: random movement, but flees from zombies.


                 */


                move(zombies, allPeople) {


                    const nearestZombie = this.findNearest(zombies);


                    let movementVectorX = 0;


                    let movementVectorY = 0;


  


                    if (nearestZombie && this.distanceTo(nearestZombie) < 100) {


                        // Flee from the nearest zombie


                        const angle = Math.atan2(this.y - nearestZombie.y, this.x - nearestZombie.x);


                        movementVectorX = Math.cos(angle) * this.fleeSpeed;


                        movementVectorY = Math.sin(angle) * this.fleeSpeed;


                        this.speed = this.fleeSpeed;


                    } else {


                        // Random walk (wander) movement


                        this.speed = this.wanderSpeed;


                        this.wanderTimer++;


                        if (this.wanderTimer > this.wanderDuration) {


                            this.dx = (Math.random() - 0.5) * this.wanderSpeed * 2;


                            this.dy = (Math.random() - 0.5) * this.wanderSpeed * 2;


                            this.wanderTimer = 0;


                        }


                        movementVectorX = this.dx;


                        movementVectorY = this.dy;


                    }


  


                    // Separation behavior from other people (classic boids rule)


                    if (peopleFlockingEnabled) {


                        let separationVectorX = 0;


                        let separationVectorY = 0;


                        for (const otherPerson of allPeople) {


                            if (otherPerson === this) continue;


                            const dist = this.distanceTo(otherPerson);


                            if (dist < separationRadius && dist > 0) {


                                const angle = Math.atan2(this.y - otherPerson.y, this.x - otherPerson.x);


                                // Push away with a force inversely proportional to distance


                                const force = (separationRadius - dist) / separationRadius;


                                separationVectorX += Math.cos(angle) * force;


                                separationVectorY += Math.sin(angle) * force;


                            }


                        }


  


                        // Normalize and blend the separation vector


                        const separationMagnitude = Math.sqrt(separationVectorX * separationVectorX + separationVectorY * separationVectorY);


                        if (separationMagnitude > 0) {


                            separationVectorX /= separationMagnitude;


                            separationVectorY /= separationMagnitude;


                            // Blend the separation with the main movement vector


                            this.dx = movementVectorX * (1 - separationInstinct) + separationVectorX * this.speed * separationInstinct;


                            this.dy = movementVectorY * (1 - separationInstinct) + separationVectorY * this.speed * separationInstinct;


                            // Clamp speed after blending


                            const finalMagnitude = Math.sqrt(this.dx * this.dx + this.dy * this.dy);


                            if (finalMagnitude > this.speed) {


                                this.dx = (this.dx / finalMagnitude) * this.speed;


                                this.dy = (this.dy / finalMagnitude) * this.speed;


                            }


                        } else {


                            // If no separation needed, use the movement vector


                            this.dx = movementVectorX;


                            this.dy = movementVectorY;


                        }


                    } else {


                        this.dx = movementVectorX;


                        this.dy = movementVectorY;


                    }


                    super.move();


                }


  


                /**


                 * Finds the nearest entity of a given type.


                 * @param {Array} others - The array of other entities to check.


                 */


                findNearest(others) {


                    let nearest = null;


                    let minDistance = 200; // Sight range for people


                    for (const other of others) {


                        const dist = this.distanceTo(other);


                        if (dist < minDistance) {


                            minDistance = dist;


                            nearest = other;


                        }


                    }


                    return nearest;


                }


  


                /**


                 * Calculates the distance to another entity.


                 * @param {object} other - The other entity.


                 */


                distanceTo(other) {


                    const dx = this.x - other.x;


                    const dy = this.y - other.y;


                    return Math.sqrt(dx * dx + dy * dy);


                }


            }


  


            /**


             * Represents a zombie.


             * Extends the base Entity class.


             */


            class Zombie extends Entity {


                constructor(x, y) {


                    // Changed color to green


                    super(x, y, 6, 1.2, '#4CAF50');


                    this.type = 'zombie';


                    this.chaseSpeed = 1.2;


                    this.wanderSpeed = 0.5;


                    this.speed = this.wanderSpeed;


                }


  


                /**


                 * Zombie's movement logic:


                 * 1. Chase nearest person or police (highest priority)


                 * 2. If no target is in sight, and flocking is enabled, apply boids rules.


                 * 3. If flocking is disabled, they just wander.


                 */


                move(people, police, allZombies) {


                    // Combine potential targets (people and police)


                    const targets = [...people, ...police];


                    const nearestTarget = this.findNearest(targets);


                    let desiredSpeed = 0;


  


                    // Priority 1: Chase a nearby target


                    if (nearestTarget) {


                        const angle = Math.atan2(nearestTarget.y - this.y, nearestTarget.x - this.x);


                        this.dx = Math.cos(angle) * this.chaseSpeed;


                        this.dy = Math.sin(angle) * this.chaseSpeed;


                        desiredSpeed = this.chaseSpeed;


                    }


                    // Priority 2: Apply boids rules if enabled and no target is in sight


                    else if (zombieFlockingEnabled) {


                        // --- 1. Calculate Cohesion (steering towards the center of mass) ---


                        let cohesionVectorX = 0;


                        let cohesionVectorY = 0;


                        let cohesionCount = 0;


                        // --- 2. Calculate Separation (steering away from close neighbors) ---


                        let separationVectorX = 0;


                        let separationVectorY = 0;


                        // --- 3. Calculate Alignment (steering to match neighbor's velocity) ---


                        let alignmentVectorX = 0;


                        let alignmentVectorY = 0;


                        let alignmentCount = 0;


  


                        // Iterate through all zombies to calculate the three boids vectors


                        for (const otherZombie of allZombies) {


                            if (otherZombie === this) continue;


                            const dist = this.distanceTo(otherZombie);


                            // Cohesion


                            if (dist < cohesionRadius) {


                                cohesionVectorX += otherZombie.x;


                                cohesionVectorY += otherZombie.y;


                                cohesionCount++;


                            }


                            // Separation


                            if (dist < separationRadius && dist > 0) {


                                const angle = Math.atan2(this.y - otherZombie.y, this.x - otherZombie.x);


                                const force = (separationRadius - dist) / separationRadius; // Push away with a force inversely proportional to distance


                                separationVectorX += Math.cos(angle) * force;


                                separationVectorY += Math.sin(angle) * force;


                            }


                            // Alignment


                            if (dist < alignmentRadius) {


                                alignmentVectorX += otherZombie.dx;


                                alignmentVectorY += otherZombie.dy;


                                alignmentCount++;


                            }


                        }


  


                        // Average the cohesion and alignment vectors


                        if (cohesionCount > 0) {


                            cohesionVectorX = (cohesionVectorX / cohesionCount) - this.x;


                            cohesionVectorY = (cohesionVectorY / cohesionCount) - this.y;


                        }


  


                        if (alignmentCount > 0) {


                            alignmentVectorX /= alignmentCount;


                            alignmentVectorY /= alignmentCount;


                        }


                        // --- Apply Instincts and Combine Vectors ---


                        let finalX = 0;


                        let finalY = 0;


  


                        // Normalize and add cohesion force


                        const cohesionMagnitude = Math.sqrt(cohesionVectorX * cohesionVectorX + cohesionVectorY * cohesionVectorY);


                        if (cohesionMagnitude > 0) {


                            finalX += (cohesionVectorX / cohesionMagnitude) * cohesionInstinct;


                            finalY += (cohesionVectorY / cohesionMagnitude) * cohesionInstinct;


                        }


  


                        // Normalize and add separation force


                        const separationMagnitude = Math.sqrt(separationVectorX * separationVectorX + separationVectorY * separationVectorY);


                        if (separationMagnitude > 0) {


                            finalX += (separationVectorX / separationMagnitude) * separationInstinct;


                            finalY += (separationVectorY / separationMagnitude) * separationInstinct;


                        }


  


                        // Normalize and add alignment force


                        const alignmentMagnitude = Math.sqrt(alignmentVectorX * alignmentVectorX + alignmentVectorY * alignmentVectorY);


                        if (alignmentMagnitude > 0) {


                            finalX += (alignmentVectorX / alignmentMagnitude) * alignmentInstinct;


                            finalY += (alignmentVectorY / alignmentMagnitude) * alignmentInstinct;


                        }


  


                        // Fallback to wandering if no forces are applied


                        if (finalX === 0 && finalY === 0) {


                            this.dx = (Math.random() - 0.5) * this.wanderSpeed * 2;


                            this.dy = (Math.random() - 0.5) * this.wanderSpeed * 2;


                        } else {


                            // Normalize the final combined vector and set it as the new direction


                            const finalMagnitude = Math.sqrt(finalX * finalX + finalY * finalY);


                            if (finalMagnitude > 0) {


                                this.dx = (finalX / finalMagnitude) * this.wanderSpeed;


                                this.dy = (finalY / finalMagnitude) * this.wanderSpeed;


                            }


                        }


                        desiredSpeed = this.wanderSpeed;


                    } else {


                        // Flocking is disabled, so zombies just wander


                        this.dx = (Math.random() - 0.5) * this.wanderSpeed * 2;


                        this.dy = (Math.random() - 0.5) * this.wanderSpeed * 2;


                        desiredSpeed = this.wanderSpeed;


                    }


                    // Clamp speed after all blending and logic


                    const finalMagnitude = Math.sqrt(this.dx * this.dx + this.dy * this.dy);


                    if (finalMagnitude > desiredSpeed) {


                        this.dx = (this.dx / finalMagnitude) * desiredSpeed;


                        this.dy = (this.dy / finalMagnitude) * desiredSpeed;


                    }


                    super.move();


                }


                /**


                 * Finds the nearest target (person or police) to chase.


                 * @param {Array} targets - The array of people and police.


                 */


                findNearest(targets) {


                    let nearest = null;


                    let minDistance = 150; // Sight range for zombies


                    for (const target of targets) {


                        const dist = this.distanceTo(target);


                        if (dist < minDistance) {


                            minDistance = dist;


                            nearest = target;


                        }


                    }


                    return nearest;


                }


                /**


                 * Calculates the distance to another entity.


                 * @param {object} other - The other entity.


                 */


                distanceTo(other) {


                    const dx = this.x - other.x;


                    const dy = this.y - other.y;


                    return Math.sqrt(dx * dx + dy * dy);


                }


            }


            /**


             * Represents a police officer.


             * Extends the base Entity class.


             */


            class Police extends Entity {


                constructor(x, y) {


                    super(x, y, 6, 1, '#007bff'); // Blue color


                    this.type = 'police';


                    this.wanderSpeed = 0.5; // New property for wandering speed


                    this.chaseSpeed = 1; // Speed when moving to a group


                    this.targetZombie = null;


                    this.shootCooldown = 30; // Cooldown for shooting, tied to slider


                    this.cooldownTimer = 0;


                    this.wanderTimer = 0;


                    this.wanderDuration = 180; // Frames before a direction change


                }


                /**


                 * Police's movement and targeting logic.


                 */


                move(zombies, people) {


                    const nearbyZombies = zombies.filter(z => this.distanceTo(z) < 200);


                    const nearbyPeople = people.filter(p => this.distanceTo(p) < 200);


                    if (nearbyZombies.length > 0) {


                        // Target the nearest zombie


                        let nearestZombie = nearbyZombies.reduce((prev, curr) =>


                            this.distanceTo(prev) < this.distanceTo(curr) ? prev : curr);


                        this.targetZombie = nearestZombie;


                        // Stay put while shooting


                        this.dx = 0;


                        this.dy = 0;


                    } else {


                        this.targetZombie = null;


                        // Check for groups of people or fleeing people to move towards


                        let fleeingPeople = nearbyPeople.filter(p => p.speed > p.wanderSpeed + 0.1);


                        // Check for people groups. A "group" is defined as 5 or more people within 150px


                        const peopleGroups = people.filter(p1 =>


                            people.filter(p2 => p1.distanceTo(p2) < 150).length >= 5


                        );


                        if (fleeingPeople.length > 0) {


                            // Find the center of the fleeing group


                            let centerX = fleeingPeople.reduce((sum, p) => sum + p.x, 0) / fleeingPeople.length;


                            let centerY = fleeingPeople.reduce((sum, p) => sum + p.y, 0) / fleeingPeople.length;


                            const angle = Math.atan2(centerY - this.y, centerX - this.x);


                            this.dx = Math.cos(angle) * this.chaseSpeed;


                            this.dy = Math.sin(angle) * this.chaseSpeed;


                        } else if (peopleGroups.length > 0) {


                            // Move towards the center of a nearby people group


                            let centerX = peopleGroups.reduce((sum, p) => sum + p.x, 0) / peopleGroups.length;


                            let centerY = peopleGroups.reduce((sum, p) => sum + p.y, 0) / peopleGroups.length;


                            const angle = Math.atan2(centerY - this.y, centerX - this.x);


                            this.dx = Math.cos(angle) * this.chaseSpeed;


                            this.dy = Math.sin(angle) * this.chaseSpeed;


                        } else {


                            // No threats or groups found, revert to slow wandering


                            this.wanderTimer++;


                            if (this.wanderTimer > this.wanderDuration) {


                                this.dx = (Math.random() - 0.5) * this.wanderSpeed * 2;


                                this.dy = (Math.random() - 0.5) * this.wanderSpeed * 2;


                                this.wanderTimer = 0;


                            }


                        }


                    }


                    this.speed = Math.sqrt(this.dx*this.dx + this.dy*this.dy);


                    super.move();


                }


  


                /**


                 * Shoots a spread of particles at a target.


                 */


                shoot() {


                    if (this.targetZombie && this.cooldownTimer <= 0) {


                        const angleToTarget = Math.atan2(this.targetZombie.y - this.y, this.targetZombie.x - this.x);


                        const spreadAngle = 0.5; // radians


                        const numParticles = 5;


                        for (let i = 0; i < numParticles; i++) {


                            const offset = (Math.random() - 0.5) * spreadAngle;


                            const particleAngle = angleToTarget + offset;


                            const particleSpeed = 5;


                            const dx = Math.cos(particleAngle) * particleSpeed;


                            const dy = Math.sin(particleAngle) * particleSpeed;


                            particles.push(new Particle(this.x, this.y, dx, dy));


                        }


                        // Use the slider value for the cooldown


                        this.cooldownTimer = (120 - policeFireRate) + 10;


                    }


                    if (this.cooldownTimer > 0) {


                        this.cooldownTimer--;


                    }


                }


  


                /**


                 * Calculates the distance to another entity.


                 * @param {object} other - The other entity.


                 */


                distanceTo(other) {


                    const dx = this.x - other.x;


                    const dy = this.y - other.y;


                    return Math.sqrt(dx * dx + dy * dy);


                }


            }


  


            /**


             * Represents a particle projectile fired by police.


             */


            class Particle {


                constructor(x, y, dx, dy) {


                    this.x = x;


                    this.y = y;


                    this.size = 2;


                    this.dx = dx;


                    this.dy = dy;


                    this.color = '#87ceeb'; // Light blue


                    this.lifetime = 120; // Frames before it disappears


                }


  


                draw() {


                    ctx.fillStyle = this.color;


                    ctx.beginPath();


                    ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);


                    ctx.fill();


                }


  


                update() {


                    this.x += this.dx;


                    this.y += this.dy;


                    this.lifetime--;


                }


            }


  


            // --- SIMULATION FUNCTIONS ---


  


            /**


             * Displays a custom message box.


             * @param {string} message - The message to display.


             */


            window.showMessage = function(message) {


                messageText.textContent = message;


                overlay.style.display = 'block';


                messageBox.style.display = 'flex';


                stopSimulation();


            }


  


            /**


             * Closes the custom message box.


             */


            window.closeMessage = function() {


                overlay.style.display = 'none';


                messageBox.style.display = 'none';


            }


  


            /**


             * Generates a single building, ensuring it doesn't overlap with existing ones.


             */


            function createBuilding() {


                const minSize = 30;


                const maxSize = 100;


                let newBuilding;


                let isColliding = true;


                let attempts = 0;


  


                while (isColliding && attempts < 50) {


                    const width = Math.random() * (maxSize - minSize) + minSize;


                    const height = Math.random() * (maxSize - minSize) + minSize;


                    const x = Math.random() * (canvas.width - width);


                    const y = Math.random() * (canvas.height - height);


                    newBuilding = { x, y, width, height };


  


                    isColliding = false;


                    for (const existingBuilding of buildings) {


                        if (isRectCollision(newBuilding, existingBuilding)) {


                            isColliding = true;


                            break;


                        }


                    }


                    attempts++;


                }


  


                if (!isColliding) {


                    buildings.push(newBuilding);


                }


            }


  


            /**


             * Checks for collision between two rectangles.


             * @param {object} rect1 - The first rectangle.


             * @param {object} rect2 - The second rectangle.


             */


            function isRectCollision(rect1, rect2) {


                return rect1.x < rect2.x + rect2.width &&


                       rect1.x + rect1.width > rect2.x &&


                       rect1.y < rect2.y + rect2.height &&


                       rect1.y + rect1.height > rect2.y;


            }


  


            /**


             * Initializes the simulation with a fresh state.


             */


            function initializeSimulation() {


                // Clear any running animation


                if (animationFrameId) {


                    cancelAnimationFrame(animationFrameId);


                }


                isRunning = false;


  


                // Update simulation parameters from sliders


                cohesionRadius = parseFloat(cohesionRadiusInput.value);


                cohesionInstinct = parseFloat(cohesionInstinctInput.value);


                separationRadius = parseFloat(separationRadiusInput.value);


                separationInstinct = parseFloat(separationInstinctInput.value);


                alignmentRadius = parseFloat(alignmentRadiusInput.value);


                alignmentInstinct = parseFloat(alignmentInstinctInput.value);


                policeFireRate = parseFloat(policeFireRateInput.value); // Set initial value from slider


                policeImmunityEnabled = policeImmunityToggle.checked; // Set initial value from toggle


  


                entities = [];


                buildings = [];


                particles = []; // Clear particles


                const zombieCount = parseInt(zombieCountInput.value, 10);


                const personCount = parseInt(personCountInput.value, 10);


                const policeCount = parseInt(policeCountInput.value, 10);


  


                // Update displays


                personCountDisplay.textContent = personCount;


                zombieCountDisplay.textContent = zombieCount;


                policeCountDisplay.textContent = policeCount;


  


                // Create buildings


                const numBuildings = 15;


                for (let i = 0; i < numBuildings; i++) {


                    createBuilding();


                }


  


                // Create initial entities


                for (let i = 0; i < zombieCount + personCount + policeCount; i++) {


                    const x = Math.random() * canvas.width;


                    const y = Math.random() * canvas.height;


                    let newEntity;


  


                    // Ensure entity is not spawned inside a building


                    let isInBuilding = false;


                    for (const building of buildings) {


                        if (x > building.x && x < building.x + building.width &&


                            y > building.y && y < building.y + building.height) {


                            isInBuilding = true;


                            break;


                        }


                    }


  


                    if (isInBuilding) {


                        i--; // Re-run the loop for this index


                        continue;


                    }


  


                    if (i < zombieCount) {


                        newEntity = new Zombie(x, y);


                    } else if (i < zombieCount + personCount) {


                        newEntity = new Person(x, y);


                    } else {


                        newEntity = new Police(x, y);


                    }


                    entities.push(newEntity);


                }


  


                draw(); // Draw the initial state


                startBtn.textContent = 'Start Simulation';


            }


  


            /**


             * The main drawing function.


             */


            function draw() {


                ctx.clearRect(0, 0, canvas.width, canvas.height); // Clear the canvas


  


                // Draw buildings


                ctx.fillStyle = '#444';


                buildings.forEach(building => {


                    ctx.fillRect(building.x, building.y, building.width, building.height);


                });


  


                // Draw entities


                entities.forEach(entity => entity.draw());


  


                // Draw particles


                particles.forEach(particle => particle.draw());


            }


  


            /**


             * The main update function for the simulation logic.


             */


            function update() {


                const zombies = entities.filter(e => e.type === 'zombie');


                const people = entities.filter(e => e.type === 'person');


                const police = entities.filter(e => e.type === 'police');


                let newEntities = [...entities];


                // Update the counter displays


                personCountDisplay.textContent = people.length;


                zombieCountDisplay.textContent = zombies.length;


                policeCountDisplay.textContent = police.length;


  


                // Move all entities


                entities.forEach(entity => {


                    if (entity.type === 'zombie') {


                        entity.move(people, police, zombies);


                    } else if (entity.type === 'person') {


                        entity.move(zombies, people);


                    } else if (entity.type === 'police') {


                        entity.move(zombies, people);


                        entity.shoot();


                    }


                });


  


                // Update and check for particle collisions


                particles = particles.filter(p => p.lifetime > 0);


                // Collision check: particle hitting a building


                for (let i = particles.length - 1; i >= 0; i--) {


                    const particle = particles[i];


                    for (const building of buildings) {


                        if (particle.x > building.x && particle.x < building.x + building.width &&


                            particle.y > building.y && particle.y < building.y + building.height) {


                            particles.splice(i, 1); // Remove the particle


                            break; // Stop checking buildings for this particle


                        }


                    }


                }


                // Update remaining particles


                particles.forEach(p => p.update());


  


                // Check for collisions and infections


                const infectedThisFrame = [];


                const destroyedThisFrame = [];


  


                // Check for zombie-person and zombie-police collisions


                for (let i = 0; i < zombies.length; i++) {


                    const zombie = zombies[i];


                    // Check for zombie-person collisions


                    for (let j = 0; j < people.length; j++) {


                        const person = people[j];


                        const distance = Math.sqrt(Math.pow(zombie.x - person.x, 2) + Math.pow(zombie.y - person.y, 2));


                        if (distance < zombie.size + person.size) {


                            infectedThisFrame.push(new Zombie(person.x, person.y));


                            newEntities = newEntities.filter(e => e !== person);


                        }


                    }


  


                    // Check for zombie-police collisions, but only if immunity is off


                    if (!policeImmunityEnabled) {


                        for (let j = 0; j < police.length; j++) {


                            const cop = police[j];


                            const distance = Math.sqrt(Math.pow(zombie.x - cop.x, 2) + Math.pow(zombie.y - cop.y, 2));


                            if (distance < zombie.size + cop.size) {


                                infectedThisFrame.push(new Zombie(cop.x, cop.y));


                                newEntities = newEntities.filter(e => e !== cop);


                            }


                        }


                    }


  


                    // Check for particle-zombie collisions


                    for (let k = 0; k < particles.length; k++) {


                        const particle = particles[k];


                        const distance = Math.sqrt(Math.pow(zombie.x - particle.x, 2) + Math.pow(zombie.y - particle.y, 2));


                        if (distance < zombie.size + particle.size) {


                            if (!destroyedThisFrame.includes(zombie)) {


                                destroyedThisFrame.push(zombie);


                                newEntities = newEntities.filter(e => e !== zombie);


                            }


                            particles.splice(k, 1);


                            k--; // Adjust index after removing a particle


                        }


                    }


                }


  


                // Add newly infected zombies to the entities list


                entities = [...newEntities, ...infectedThisFrame];


  


                // Check for end conditions


                if (people.length === 0 && police.length === 0 && isRunning) {


                    showMessage('The zombies have won! No people or police left.');


                } else if (zombies.length === 0 && isRunning) {


                    showMessage('The people and police have won! No zombies left.');


                }


            }


  


            /**


             * The main game loop.


             */


            function gameLoop() {


                update();


                draw();


                animationFrameId = requestAnimationFrame(gameLoop);


            }


  


            /**


             * Starts the simulation.


             */


            function startSimulation() {


                if (!isRunning) {


                    gameLoop();


                    isRunning = true;


                    startBtn.textContent = 'Running...';


                }


            }


  


            /**


             * Stops the simulation.


             */


            function stopSimulation() {


                if (animationFrameId) {


                    cancelAnimationFrame(animationFrameId);


                    animationFrameId = null;


                }


                isRunning = false;


                startBtn.textContent = 'Start Simulation';


            }


            // --- EVENT LISTENERS FOR CONTROLS ---


            cohesionRadiusInput.addEventListener('input', () => {


                cohesionRadius = parseFloat(cohesionRadiusInput.value);


            });


            cohesionInstinctInput.addEventListener('input', () => {


                cohesionInstinct = parseFloat(cohesionInstinctInput.value);


            });


            separationRadiusInput.addEventListener('input', () => {


                separationRadius = parseFloat(separationRadiusInput.value);


            });


            separationInstinctInput.addEventListener('input', () => {


                separationInstinct = parseFloat(separationInstinctInput.value);


            });


            alignmentRadiusInput.addEventListener('input', () => {


                alignmentRadius = parseFloat(alignmentRadiusInput.value);


            });


            alignmentInstinctInput.addEventListener('input', () => {


                alignmentInstinct = parseFloat(alignmentInstinctInput.value);


            });


            policeFireRateInput.addEventListener('input', () => {


                // Update the fire rate variable when the slider changes


                policeFireRate = parseFloat(policeFireRateInput.value);


            });


            policeImmunityToggle.addEventListener('change', (e) => {


                // Update the immunity variable when the toggle changes


                policeImmunityEnabled = e.target.checked;


            });


            peopleFlockingToggle.addEventListener('change', (e) => {


                peopleFlockingEnabled = e.target.checked;


            });


            zombieFlockingToggle.addEventListener('change', (e) => {


                zombieFlockingEnabled = e.target.checked;


            });


  


            // --- EVENT LISTENERS ---


            startBtn.addEventListener('click', startSimulation);


            resetBtn.addEventListener('click', initializeSimulation);


  


            // Initial setup


            initializeSimulation();


        };


