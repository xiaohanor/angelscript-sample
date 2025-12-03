struct FDentistCandyDispenserPlayerDatum
{
	FHazeActionQueue ActionQueue;
	float StartTime;
};

struct FDentistCandyDispenserPlayerParams
{
	AHazePlayerCharacter Player;
};

UCLASS(Abstract)
class ADentistCandyDispenser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BodyMeshComp;

	UPROPERTY(DefaultComponent)
	USceneComponent HeadRootComp;

	UPROPERTY(DefaultComponent, Attach = HeadRootComp)
	UStaticMeshComponent HeadMeshComp;

	UPROPERTY(DefaultComponent, Attach = HeadRootComp)
	UArrowComponent LaunchComponent;

	UPROPERTY(DefaultComponent, Attach = HeadRootComp)
	UStaticMeshComponent CandyMeshComp;

	UPROPERTY(DefaultComponent, Attach = HeadRootComp)
	UDentistGroundPoundAutoAimComponent GroundPoundAutoAimComp;

	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent MovementResponseComp;

	UPROPERTY(EditInstanceOnly, Category = "Candy Dispenser")
	float LaunchDuration = 10;

	UPROPERTY(EditInstanceOnly, Category = "Candy Dispenser")
	float LaunchSpeed = 3000;

	UPROPERTY(EditInstanceOnly, Category = "Candy Dispenser")
	float Gravity = 2000;

	UPROPERTY(EditDefaultsOnly, Category = "Candy Dispenser")
	TSubclassOf<ADentistDispensedCandy> DispenseCandyClass;

	UPROPERTY(EditDefaultsOnly, Category = "Candy Dispenser")
	FRuntimeFloatCurve MoveDownCurve;

	UPROPERTY(EditDefaultsOnly, Category = "Candy Dispenser")
	FRuntimeFloatCurve MoveUpCurve;

	private TPerPlayer<FDentistCandyDispenserPlayerDatum> PlayerData;
	private float InitialRelativeHeight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementResponseComp.OnGroundPoundedOn.AddUFunction(this, n"OnGroundPoundedOn");

		for(FDentistCandyDispenserPlayerDatum& PlayerDatum : PlayerData)
			PlayerDatum.ActionQueue.Initialize(this);

		InitialRelativeHeight = HeadRootComp.RelativeLocation.Z;

		AddActorTickBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bBothFinished = true;

		for(FDentistCandyDispenserPlayerDatum& PlayerDatum : PlayerData)
		{
			if(PlayerDatum.ActionQueue.IsEmpty())
				continue;

			PlayerDatum.ActionQueue.Update(DeltaSeconds);
			
			if(!PlayerDatum.ActionQueue.IsEmpty())
				bBothFinished = false;
		}

		if(bBothFinished)
			AddActorTickBlock(this);
	}

	UFUNCTION()
	private void OnGroundPoundedOn(AHazePlayerCharacter Player, FHitResult Impact)
	{
		if(!Player.HasControl())
			return;

		CrumbStartDispensingCandy(Player, Time::PredictedGlobalCrumbTrailTime);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartDispensingCandy(AHazePlayerCharacter Player, float StartTime)
	{
		FDentistCandyDispenserPlayerDatum& PlayerDatum = PlayerData[Player];

		PlayerDatum.StartTime = StartTime;

		if(!PlayerDatum.ActionQueue.IsEmpty())
			PlayerDatum.ActionQueue.Empty();

		FDentistCandyDispenserPlayerParams PlayerParams;
		PlayerParams.Player = Player;

		PlayerDatum.ActionQueue.Duration(0.1, this, n"MoveDown", PlayerParams);
		PlayerDatum.ActionQueue.Event(this, n"DispenseCandy", PlayerParams);
		PlayerDatum.ActionQueue.Duration(0.5, this, n"MoveUp", PlayerParams);

		if(IsLatestGroundPound(Player))
			UDentistCandyDispenserEventHandler::Trigger_OnStartMovingDown(this);

		RemoveActorTickBlock(this);
	}

	UFUNCTION()
	private void MoveDown(float Alpha, FDentistCandyDispenserPlayerParams PlayerParams)
	{
		// The other player animation is taking precedent
		if(!IsLatestGroundPound(PlayerParams.Player))
			return;

		FVector RelativeLocation = HeadRootComp.RelativeLocation;
		float Height = MoveDownCurve.GetFloatValue(Alpha);
		RelativeLocation.Z = InitialRelativeHeight + Height;
		HeadRootComp.SetRelativeLocation(RelativeLocation);
	}

	UFUNCTION()
	private void DispenseCandy(FDentistCandyDispenserPlayerParams PlayerParams)
	{
		FVector Location = LaunchComponent.WorldLocation;
		FRotator Rotation = LaunchComponent.WorldRotation;
		ADentistDispensedCandy DispenseCandy = SpawnActor(DispenseCandyClass, Location, Rotation, bDeferredSpawn = true);
		DispenseCandy.Trajectory = GetTrajectory();
		DispenseCandy.SetLifeSpan(LaunchDuration);
		FinishSpawningActor(DispenseCandy);

		FDentistCandyDispenserOnCandyDispensedEventData EventData;
		EventData.Location = Location;
		EventData.Rotation = Rotation;
		UDentistCandyDispenserEventHandler::Trigger_OnCandyDispensed(this, EventData);

		if(IsLatestGroundPound(PlayerParams.Player))
			UDentistCandyDispenserEventHandler::Trigger_OnStartMovingUp(this);
	}

	UFUNCTION()
	private void MoveUp(float Alpha, FDentistCandyDispenserPlayerParams PlayerParams)
	{
		// The other player animation is taking precedent
		if(!IsLatestGroundPound(PlayerParams.Player))
			return;

		FVector RelativeLocation = HeadRootComp.RelativeLocation;
		float Height = MoveUpCurve.GetFloatValue(Alpha);
		RelativeLocation.Z = InitialRelativeHeight + Height;
		HeadRootComp.SetRelativeLocation(RelativeLocation);
	}

	FTraversalTrajectory GetTrajectory() const
	{
		FTraversalTrajectory Trajectory;
		Trajectory.LaunchLocation = LaunchComponent.WorldLocation;
		Trajectory.LaunchVelocity = LaunchComponent.ForwardVector * LaunchSpeed;
		Trajectory.Gravity = FVector::DownVector * Gravity;
		return Trajectory;
	}

	bool IsLatestGroundPound(AHazePlayerCharacter Player) const
	{
		if(PlayerData[Player].StartTime < PlayerData[Player.OtherPlayer].StartTime)
			return false;

		return true;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		GetTrajectory().DrawDebug(FLinearColor::White, 0);
	}
#endif
};