class ASolarFlareGrapplePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateRoot;

	UPROPERTY(EditAnywhere)
	AGrapplePoint ActiveGrapplePoint;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareGrapplePlatformActivatedCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareGrapplePlatformReturnCapability");

	UPROPERTY(EditAnywhere)
	bool bAttachPoint = false;

	float DelayMoveTime = 0.5;
	float MoveTime;
	float FallWaitDuration = 1.0;
	float FallTime;
	bool bGrappling;

	AHazePlayerCharacter GrappledPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bAttachPoint)
			ActiveGrapplePoint.AttachToComponent(RotateRoot, NAME_None, EAttachmentRule::KeepWorld);
		
		ActiveGrapplePoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPointEvent");
	}

	UFUNCTION()
	private void OnPlayerInitiatedGrappleToPointEvent(AHazePlayerCharacter Player,
	                                                  UGrapplePointBaseComponent GrapplePoint)
	{
		MoveTime = Time::GameTimeSeconds + DelayMoveTime;
		bGrappling = true;
	}

	bool PlatformCanMove()
	{
		return Time::GameTimeSeconds > MoveTime;
	}
}