UCLASS(Abstract)
class AIslandStormdrainWaterSurfaceFloatingPlatform : AAmbientMovement
{
	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent, Attach = ActualMesh)
	USceneComponent FauxRoot;
	default FauxRoot.RelativeLocation = FVector(200, 200, 0);

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = FauxRoot)
	UFauxPhysicsConeRotateComponent ConeRotateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent RealMesh;
	default RealMesh.RelativeLocation = FVector(-200, -200, 0);

	float PreviousSin;
	int PreviousSinSign = 1;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ActualMesh.SetHiddenInGame(true);
		RealMesh.StaticMesh = ActualMesh.StaticMesh;

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpacted");
		UPlayerJumpComponent::GetOrCreate(Game::Mio).OnJump.AddUFunction(this, n"OnPlayerJump");
		UPlayerJumpComponent::GetOrCreate(Game::Zoe).OnJump.AddUFunction(this, n"OnPlayerJump");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);
		
		float Time = Time::PredictedGlobalCrumbTrailTime;
		float Sin = Math::Sin(Time * BobSpeed);

		int SinSign = int(Math::Sign(Sin - PreviousSin));

		if(SinSign != PreviousSinSign)
		{
			if(SinSign == 1)
				UIslandStormdrainWaterSurfaceFloatingPlatformEffectHandler::Trigger_OnStartBobbingUp(this);
			else
				UIslandStormdrainWaterSurfaceFloatingPlatformEffectHandler::Trigger_OnStartBobbingDown(this);
		}

		PreviousSinSign = SinSign;
		PreviousSin = Sin;
	}

	UFUNCTION()
	private void OnGroundImpacted(AHazePlayerCharacter Player)
	{
		UIslandStormdrainWaterSurfaceFloatingPlatformEffectHandler::Trigger_OnPlayerLand(this);

		TranslateComp.ApplyImpulse(Player.ActorLocation, -Player.ActorUpVector * 100);
		ConeRotateComp.ApplyImpulse(Player.ActorLocation, -Player.ActorUpVector * 80);
	}

	UFUNCTION()
	private void OnPlayerJump(AHazePlayerCharacter Player)
	{
		auto MoveComp = UPlayerMovementComponent::Get(Player);
		if(MoveComp.HasGroundContact() && MoveComp.GroundContact.Actor == this)
			UIslandStormdrainWaterSurfaceFloatingPlatformEffectHandler::Trigger_OnPlayerJump(this);
	}
}

UCLASS(Abstract)
class UIslandStormdrainWaterSurfaceFloatingPlatformEffectHandler : UHazeEffectEventHandler
{
	// Triggers when the player jumps while standing on the platform.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerJump() {}

	// Triggers when the player lands on the platform.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerLand() {}

	// Triggers when the platform starts bobbing down.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartBobbingDown() {}

	// Triggers when the platform starts bobbing up.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartBobbingUp() {}
}