class ASkylineWhipHoop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGrappleLaunchPointComponent GrappleLaunchPointComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTargetComp;

	UPROPERTY(DefaultComponent, Attach = WhipTargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.GrabMode = EGravityWhipGrabMode::Sling;
	default WhipResponseComp.bAllowMultiGrab = false;

	UPROPERTY()
	float HoverTime = 5.0;
	float ExpireTime = 0.0;
	bool bIsThrown = false;

	FTransform InitialRelativeTransform;

	UPROPERTY()
	UAnimSequence SitAnim;

	UPROPERTY()
	UAnimSequence AirAnim;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRelativeTransform = ActorRelativeTransform;

		GrappleLaunchPointComp.Disable(this);

		WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		WhipResponseComp.OnThrown.AddUFunction(this, n"HandleThrown");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsThrown && Time::GameTimeSeconds > ExpireTime)
		{
			Reset();
		}
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		auto Player = Cast<AHazePlayerCharacter>(UserComponent.Owner);
		GrappleLaunchPointComp.EnableForPlayer(Player.OtherPlayer, this);
	}

	UFUNCTION()
	private void HandleThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		bIsThrown = true;
		ExpireTime = Time::GameTimeSeconds + HoverTime;

//		GrappleLaunchPointComp.Disable(this);
//		WhipTargetComp.Disable(this);
	}

	UFUNCTION()
	void Reset()
	{
		bIsThrown = false;
	}
};