namespace TeenDragonLocomotionTags
{
	// BASE MOVEMENT
	// For when on ground
	const FName Movement = n"Movement";
	// For when in air
	const FName AirMovement = n"AirMovement";
	// On jump
	const FName Jump = n"Jump";
	// While dashing
	const FName DragonDash = n"DragonDash";
	// On the frame the dragon lands 
	const FName Landing = n"Landing";
	// While climbing ledges
	const FName TeenDragonLedgeUp = n"TeenDragonLedgeUp";
	// While going down ledges
	const FName TeenDragonLedgeDown = n"TeenDragonLedgeDown";
	// While pushing Decimator
	const FName DecimatorPush = n"DecimatorPush";



	// TAIL DRAGON
	// tail dragons roll
	const FName RollMovement = n"RollMovement";
	// For when the tail dragon rolls into a wall and gets knocked back
	const FName TailTeenHitWall = n"TailTeenHitWall";
	// For when the tail dragon pulls the pulls interactions in the world
	const FName TaillTeenPull = n"TaillTeenPull";
	// For when climbing on a wall
	const FName TailTeenClimb = n"TailTeenClimb";


	
	// ACID DRAGON
	// Acid Dragon shoot override feature
	const FName AcidTeenShoot = n"AcidTeenShoot";
	// While in air currents or gliding
	const FName AcidTeenHover = n"AcidTeenHover";
	// Glide Boost Ring
	const FName AcidTeenSpeedRing = n"AcidTeenSpeedRing";
}