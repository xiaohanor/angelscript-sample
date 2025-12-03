struct FSwimmingEffectEventData
{
	UPROPERTY()
	FVector SurfaceLocation;

	//Complete velocity when breach activated
	UPROPERTY()
	FVector BreachVelocity;
	
	//Player Up Aligned breach velocity
	UPROPERTY()
	float BreachVerticalSpeed;
}

UCLASS(Abstract)
class UPlayerSwimmingEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadWrite, NotEditable)
	AHazePlayerCharacter Player;

	UPROPERTY()
	bool bInSketchBook = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintEvent)
	void SketchBookDisableSwimVFX()
	{
		
	}

	//Triggered whenever we detect an imminent Dive
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ApexDive_Detected(FSwimmingEffectEventData Data)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Surface_Started(FSwimmingEffectEventData Data)
	{

	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Surface_Stopped(FSwimmingEffectEventData Data)
	{
		
	}

	/**
	 * Called when we transition from Apex Dive (aerial dive) into swimming
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Surface_ApexDive_Impacted(FSwimmingEffectEventData Data)
	{

	}

	/**
	 * Called when we transition from Skydive dive into swimming
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Surface_SkydiveImpacted(FSwimmingEffectEventData Data)
	{

	}

	/**
	 * Called when we go from generic airborne state into swimming
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Surface_Impacted(FSwimmingEffectEventData Data)
	{

	}

	/**
	 * Called When we Breach / Ascend from underwater into surface swimming
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Surface_Breached(FSwimmingEffectEventData Data)
	{

	}

	/**
	 * Called when we jump out of surface swimming
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Surface_JumpedOut(FSwimmingEffectEventData Data)
	{

	}

	/**
	 * Called when we initiate surface dash
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Surface_DashStarted(FSwimmingEffectEventData Data)
	{

	}

	/**
	 * Called when we finish the surface dash
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Surface_DashStopped(FSwimmingEffectEventData Data)
	{

	}

	/**
	 * Called when we press to Enter Underwater swimming from surface
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Surface_Dive(FSwimmingEffectEventData Data)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Underwater_Started(FSwimmingEffectEventData Data)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Underwater_Stopped(FSwimmingEffectEventData Data)
	{

	}

	/**
	 * Called when we initiate a dash when underwater
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Underwater_DashStarted(FSwimmingEffectEventData Data)
	{

	}

	/**
	 * Called when we finish the underwater dash 
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Underwater_DashStopped(FSwimmingEffectEventData Data)
	{

	}
	
	
	/**
	 * Triggered When we breach surface while performing underwater dash (Currently not implemented)
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Surface_DashBreach(FSwimmingEffectEventData Data)
	{

	}

	/**
	 * Triggered if we exit swimming from underwater and we didnt go through a surface capability or dash
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Underwater_ExitBypassedSurface(FSwimmingEffectEventData Data)
	{
		
	}
}