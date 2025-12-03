struct FLedgeRunStartedEffectEventParams
{
	UPROPERTY()
	ELeftRight ContactHand;
}

struct FSlideStartedEffectEventParams
{
	UPROPERTY()
	EPhysicalSurface SurfaceType;
}

struct FHighSpeedLandingStartedEffectEventParams
{
	UPROPERTY()
	EPhysicalSurface SurfaceType;
}


UCLASS(Abstract)
class UPlayerCoreMovementEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadWrite, NotEditable)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadWrite, NotEditable)
	UPlayerFootstepTraceComponent FootStepComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FootStepComp = UPlayerFootstepTraceComponent::Get(Player);
	}

	UFUNCTION()
	bool VerifyInDesertLevel()
	{
		return UPlayerSlideSettings::GetSettings(Player).bInDesertLevel;
	}

	/**
	 * Triggered when the player performs a standard jump from the ground.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundJump_Started()
	{
	}

	/**
	 * Triggered when a ground jump either gets cancelled by a different move, or
	 * reaches the apex of the jump.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundJump_CancelledOrReachedApex()
	{
	}

	/**
	 * Triggered whenever the player lands on the ground.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Landed()
	{
	}

	/**
	 * Triggered when the player performs a double jump in the air.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AirJump_Started()
	{
	}

	/**
	 * Triggered when an air jump either gets cancelled by a different move, or
	 * reaches the apex of the jump.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AirJump_CancelledOrReachedApex()
	{
	}

	/**
	 * Triggered when the player performs an air dash.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AirDash_Started()
	{
	}

	/**
	 * Triggered when the air dash is finished or interrupted by something.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AirDash_Stopped()
	{
	}

	/**
	 * Triggered when the player performs a step dash on the ground.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StepDash_Started()
	{
	}

	/**
	 * Triggered when the step dash is finished or interrupted by something.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StepDash_Stopped()
	{
	}

	/**
	 * Triggered when the player performs a roll dash on the ground.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollDash_Started()
	{
	}

	/**
	 * Triggered when the roll dash is finished or interrupted by something.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollDash_Stopped()
	{
	}

	/**
	 * Triggered when the player starts wall running.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WallRun_Started()
	{
	}

	/**
	 * Triggered whenever the player jumps off from a wallrun.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WallRun_JumpOff()
	{
	}

	/**
	 * Triggered when player Transfer jumps from LedgeRun to a new Wall/LedgeRun
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Wallrun_Transfer()
	{
		
	}

	/**
	 * Triggered when a wallrun is finished or interrupted by something.
	 *  Note: Both Stopped and JumpOff can happen at the same time!
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WallRun_Stopped()
	{
	}

	/**
	 * Triggered when the player starts LedgeRunning
	 */
	 UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	 void LedgeRun_Started(FLedgeRunStartedEffectEventParams Params)
	 {

	 }

	/*
	* Triggered when the player stops LedgeRunning
	*/	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LedgeRun_Stopped()
	{

	}

	/**
	 * Triggered when the player cancels LedgeRun back into wallrun
	 * NOTE: Both this and Stopped can fire at the same time 
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LedgeRun_Cancel()
	{

	}

	/**
	 * Triggered when the player starts wall scrambling.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WallScramble_Started()
	{
	}

	/**
	 * Triggered whenever the player jumps off from a wall scramble.
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WallScramble_JumpOff()
	{
	}

	/**
	 * Triggered when a wall scramble is finished or interrupted by something.
	 *  Note: Both Stopped and JumpOff can happen at the same time!
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WallScramble_Stopped()
	{
	}

	/**
	 * Triggered When RollDashJump is initiated
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollDashJumpStarted()
	{
		
	}

	/**
	 * Triggered when rolldashJump deactivates
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollDashJumpCancelledOrReachedApex()
	{
		
	}

	/**
	 * Triggered when sprint is initially activated / we perform overspeed entry
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SprintActivated()
	{

	}

	/**
	 * Mantles
	 */

	// Triggered when player Starts moving towards ledge position
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Roll_EnterStarted()
	{

	}

	// Triggered when player starts the Exit "Roll" (This coincides with the Enter finishing)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Roll_ExitStarted()
	{

	}

	//Triggered when player has finished the Exit "Roll" and has regained control
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Roll_ExitFinished()
	{

	}

	//Triggered when player initiates an airborne mantle at waist height
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Airborne_Low_EnterStarted()
	{

	}

	//Triggered when player has finished moving into position below the ledge and begins to climb up
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Airborne_Low_ExitStarted()
	{

	}

	//Triggered when Player has finished moving onto the ledge and regains control
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Airborne_Low_ExitFinished()
	{

	}

	//Triggered when player triggers a Climb mantle when jumping up from below a ledge
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Climb_EnterStarted()
	{

	}

	//Triggered when player has finished moving into position below the ledge and begins to climb up
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Climb_ExitStarted()
	{

	}

	//Triggered when player has finished moving onto the ledge and regains control
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Climb_ExitFinished()
	{

	}

	//Triggered when player wallscrambles and reaches a ledge
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Scramble_EnterStarted()
	{

	}

	//Triggered when player has finished moving into position below the ledge and begins to climb up
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Scramble_ExitStarted()
	{

	}

	//Triggered when player has finshed moving onto the ledge and regains control
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Mantle_Scramble_ExitFinished()
	{

	}

	/**
	 * Slide
	 */

	//Triggered when player slide movement starts
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Slide_Start(FSlideStartedEffectEventParams Params)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Slide_Start_Water()
	{

	}

	//Triggered when player slide movement stops
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Slide_Stop()
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Slide_Stop_Water()
	{
		
	}

	//Triggered when player initiates a jump during slide
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Slide_Jump()
	{

	}

	/**
	 * Landings / HighSpeedLanding
	 */

	//Triggered every time we detect a new imminent Highspeed landing
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Landing_HighSpeed_Detected(FHighSpeedLandingDetectedParams Params)
	{
		
	}
	
	//Triggered when player lands during high horizontal speed and starts decelerating
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Landing_HighSpeed_Start(FHighSpeedLandingStartedEffectEventParams Params)
	{

	}

	//Triggered when player has slowed down enough to return to normal player movement OR we deactivate capability due to other reason such as becoming airborne
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Landing_HighSpeed_Stop()
	{

	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Skydive_Started()
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Skydive_Stopped()
	{
		
	}

	/**
	 * Adding Contextual moves here for now and we will see if we want to separate them into their own effect handler later [AL + RS]
	 */

	/**
	 * Perch
	 */

	/***
	 * Triggered when player starts perching on a a point or spline
	 * NOTE: Can occur on the same frame that LandOnPoint triggers
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Perch_Started()
	{

	}

	//Triggered when player starts perching on a a point or spline
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Perch_Stopped()
	{

	}

	//Triggered when Players initiate a Transition Jump to a specific point/spline
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Perch_JumpTo()
	{

	}

	//Triggered when players jump off of a point/spline without triggering a jumpto to a new point/spline
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Perch_JumpOff()
	{

	}

	//Triggered whenever players land on a Point or Spline
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Perch_LandOnPoint()
	{

	}
	
	//Triggered when players start a dash on a perch spline
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Perch_Spline_DashStarted()
	{

	}

	//Triggered when players finish a dash on a perch spline
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Perch_Spline_DashStopped()
	{

	}

	//Triggered when players Jump while on a perch spline without leaving the spline lock / Triggering a Jump To
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Perch_Spline_Jump()
	{

	}

	/**
	 * Pole
	 */

	//Triggered when players attach to the pole / Start lerping into position
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pole_StartPoleClimb()
	{

	}

	//Triggered whenever players detach from the pole / climb up onto perch ontop of it
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pole_StopPoleClimb()
	{

	}

	//Triggered when player has finished entering pole (At the moment they reach the pole/attach from a ground/airborne enter)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pole_Enter_Finished()
	{

	}

	//Triggered when players cancel poleclimb by letting go
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pole_LetGo()
	{

	}

	//Triggered when players Trigger a jump out away from the pole
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pole_JumpOut()
	{

	}

	//Triggered when player initiates a pole dash
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pole_DashStarted()
	{

	}

	//Triggered when player finishes a pole dash
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pole_DashStopped()
	{

	}

	//Triggered when player initiates transition to perch on top of pole
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pole_ClimbUpToPerchStarted()
	{

	}

	//Triggered when player finishes transition to perch on top of pole
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pole_ClimbUpToPerchFinished()
	{

	}

	//Triggered when player initiates transition down from perch down to poleclimb
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pole_ClimbDownFromPerchStarted()
	{

	}

	//Triggered when player finishes transition down from perch to poleclimb
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Pole_ClimbDownFromPerchFinished()
	{

	}

	/**
	 * Ladder
	 */

	//Triggered when player starts LadderClimbing, will trigger whenever they start lerping into position
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Start()
	{

	}

	//Triggered when player stops ladder climbing for any reason
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Stop()
	{

	}

	//Triggered whenever player finishes entering the ladder / lerping into position and can start ladder movement from midair / wallrun
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Enter_Airborne_Finished()
	{

	}

	//Triggered whenever player finishes entering the ladder from the bottom entry point and can start ladder movement
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Enter_Bottom_Finished()
	{

	}

	//Triggered whenever player finishes entering the ladder from the top entry point and can start ladder movement
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Enter_Top_Finished()
	{

	}

	//Triggered when player initiates a dash on the ladder
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Dash_Started()
	{

	}

	//Triggered when player finishes a dash on the ladder and returns to normal ladder movement
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Dash_Finished()
	{

	}

	//Triggered whenever player cancels/lets go of the ladder by pressing cancel
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Cancel()
	{

	}

	//Triggered when player initiates a jump out from the ladder
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_JumpOut()
	{

	}

	//Triggered when player initiates an exit on the top of the ladder
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Exit_Top_Started()
	{

	}

	//Triggered when player finishes an exit on the top of the ladder
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Exit_Top_Finished()
	{

	}

	//Triggered when player initiates an exit on the bottom of the ladder
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Exit_Bottom_Started()
	{

	}

	//Triggered when player finishes an exit on the bottom of the ladder
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Ladder_Exit_Bottom_Finished()
	{

	}

	/**
	 * Grapple
	 */

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Grapple_Enter_Finished_Grounded()
	{

	}

	//Triggered when Grounded GrappleToPoint exit is performed
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Grapple_GroundedExit()
	{

	}

	/**
	 * 
	 */
};

struct FHighSpeedLandingDetectedParams
{
	float TimeUntilDetectedLanding = 0;
}