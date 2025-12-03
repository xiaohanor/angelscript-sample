UCLASS(Abstract)
class AMeltdownWorldSpinChaseActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.SetVisibility(false);

	UPROPERTY(DefaultComponent)
	UBillboardComponent DistanceBillboard;

	UPROPERTY(EditAnywhere)
	AMeltdownTransitionGlitchSingleMash Interact;

	UPROPERTY(EditAnywhere)
	AStaticMeshActor RespawnTarget;

	UPROPERTY(EditAnywhere)
	AStaticMeshActor EndStateTarget;

	UPROPERTY(EditAnywhere)
	float RubberbandMaxSpeed = 300;

	UPROPERTY(EditAnywhere)
	float RubberbandMinSpeed = 150;

	UPROPERTY(EditAnywhere)
	float RubberbandMinDistanceToPlayer = 400;

	UPROPERTY(EditAnywhere)
	float RubberbandMaxDistanceToPlayer = 1000;

	UPROPERTY()
	bool bChaseActive;

	float PlayerLocation;

	float ObstacleLocation;

	float MinDistanceWhileInteracting;

	bool bIsInteracting;

	UPROPERTY(EditAnywhere)
	bool bIsWinterBase;

	FHazeAcceleratedFloat AccSpeed;
	UPROPERTY(EditAnywhere)
	int PlaneIndex;

	float InAnimationTime = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		if(Interact != nullptr)
			Interact.OnThreeShotEnterBlendedIn.AddUFunction(this, n"LockedIn");

		bEffectEnabled = true;
		
	}

	bool bEffectEnabled = true;

	UFUNCTION(BlueprintCallable)
	void SetEffectEnabled(bool bEnabled)
	{
		bEffectEnabled = bEnabled;
	}

	UFUNCTION()
	private void LockedIn(AHazePlayerCharacter Player, AThreeShotInteractionActor Interaction)
	{
		bIsInteracting = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AHazePlayerCharacter Zoe;
		InAnimationTime = Math::FInterpTo(InAnimationTime, 0, DeltaSeconds, 1);

	//	Debug::DrawDebugBox(DistanceBillboard.WorldLocation, DistanceBillboard.BoundsExtent, Thickness = 10, Duration = -1);
		
		Zoe = Game::GetZoe();

		if(bIsWinterBase)
			ObstacleLocation = DistanceBillboard.WorldLocation.Z;
		else
			ObstacleLocation = DistanceBillboard.WorldLocation.Y;
		
		if(bIsWinterBase)
			PlayerLocation = Zoe.ActorLocation.Z;
		else
			PlayerLocation = Zoe.ActorLocation.Y;

		float MinDistanceToPlayer = MAX_flt;

		float CurrentDistance = PlayerLocation - ObstacleLocation;

	//	Print(""+ ActorLocation.Y);

		if(CurrentDistance <= MinDistanceToPlayer)
			MinDistanceToPlayer = CurrentDistance;
			
		float TargetSpeed = Math::GetMappedRangeValueClamped(FVector2D(RubberbandMinDistanceToPlayer, RubberbandMaxDistanceToPlayer), FVector2D(RubberbandMinSpeed,RubberbandMaxSpeed), MinDistanceToPlayer);

		AccSpeed.AccelerateTo(TargetSpeed, 4.0, DeltaSeconds);

		if(Zoe == nullptr)
			TargetSpeed = 100.0;

		AddActorLocalOffset(FVector(0,0, AccSpeed.Value * DeltaSeconds));

		MinDistanceWhileInteracting = PlayerLocation - ObstacleLocation;

		if(ActorLocation.Y >= 26500 && !bIsWinterBase)
			DeActivate();

		if(bIsInteracting == true && MinDistanceWhileInteracting <= 200)
		{
			TargetSpeed = 0.0;
			DeActivate();
		}

		FVector EdgeLocation = DistanceBillboard.GetWorldLocation();
		FVector EdgeDirection = DistanceBillboard.GetUpVector();

		// don't touch the radius pls
		float Radius = 100000;
		if(!bEffectEnabled)
			Radius = 0;
		
		AMeltdownWorldSpinChasePlanes PlanesManager = TListedActors<AMeltdownWorldSpinChasePlanes>().Single;
		if(PlanesManager != nullptr)
			PlanesManager.SetPlane(PlaneIndex, EdgeLocation, EdgeDirection, InAnimationTime);
		
	}

	UFUNCTION(BlueprintCallable)
	void Activate()
	{
		SetActorTickEnabled(true);
		InAnimationTime = 1;
		bChaseActive = true;
		UMeltdownWorldSpinChaseActorEventHandler::Trigger_Started(this);
	}

	UFUNCTION(BlueprintCallable)
	void DeActivate()
	{
		RubberbandMaxSpeed = 0;
		RubberbandMinSpeed = 0;
		bChaseActive = false;
		UMeltdownWorldSpinChaseActorEventHandler::Trigger_Stop(this);
	//	AddActorDisable(this);
	}

	UFUNCTION(BlueprintCallable)
	void Respawn()
	{
		SetActorLocation(RespawnTarget.ActorLocation);
		RubberbandMaxSpeed = 400;
		RubberbandMinSpeed = 100;
		Activate();
	}

	UFUNCTION(BlueprintCallable)
	void EndState()
	{
		SetActorLocation(EndStateTarget.ActorLocation);
		RubberbandMaxSpeed = 0;
		RubberbandMinSpeed = 0;
		Activate();
	}


	UFUNCTION(BlueprintCallable)
	void SlowDown()
	{
		RubberbandMaxSpeed = 400;
		RubberbandMinSpeed = 100;
	}
};

UCLASS(Abstract)
class UMeltdownWorldSpinChaseActorEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Started() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Stop() {}

};