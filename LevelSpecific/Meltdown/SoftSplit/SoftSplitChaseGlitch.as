class ASoftSplitChaseGlitch : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent)
	UBillboardComponent DistanceBillboard;

	UPROPERTY(EditAnywhere)
	float RubberbandMaxSpeed = 300.0;

	UPROPERTY(EditAnywhere)
	float RubberbandMinSpeed = 150.0;

	UPROPERTY(EditAnywhere)
	float RubberbandMinDistanceToPlayer = 400;

	UPROPERTY(EditAnywhere)
	float RubberbandMaxDistanceToPlayer = 1000;

	UPROPERTY(EditAnywhere)
	AMeltdownTransitionGlitchDoubleMash Interact;

	// Disable these respawn points when the chase glitch reaches them
	UPROPERTY(EditInstanceOnly)
	TArray<ARespawnPoint> RespawnPointsToDisable;

	// Disable respawn points when the chase glitch gets within this height of the respawn points
	UPROPERTY(EditInstanceOnly)
	float DisableRespawnPointDistance = 200.0;

	FHazeAcceleratedFloat AccSpeed;

	UPROPERTY(DefaultComponent)
	UPostProcessComponent PostProcessComponent;
	default PostProcessComponent.bUnbound = true;

	UPROPERTY(EditAnywhere)
	bool bPostprocessWhitespace;
	
	UPROPERTY(EditAnywhere)
	UMaterialInterface PostProcessMaterial;
	UMaterialInstanceDynamic PostProcessMaterialDynamic;

	UPROPERTY(EditAnywhere)
	AActor CompletedPosition;

	float InAnimationTime = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SetActorTickEnabled(false);


		PostProcessMaterialDynamic = Material::CreateDynamicMaterialInstance(this, PostProcessMaterial);
		if(PostProcessMaterialDynamic != nullptr)
		{
			FPostProcessSettings PPSettings;
			FWeightedBlendable WeightedBlendable;
			WeightedBlendable.Object = PostProcessMaterialDynamic;
			WeightedBlendable.Weight = 1.0;
			PostProcessComponent.Settings.WeightedBlendables.Array.Empty();
			PostProcessComponent.Settings.WeightedBlendables.Array.Add(WeightedBlendable);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AHazePlayerCharacter CurrentClosestPlayer;
		float MinDistanceToPlayer = MAX_flt;

		for (AHazePlayerCharacter Player: Game::Players)
		{
			if(Player.IsPlayerDead())
				continue;
			float CurrentDistance = Player.ActorLocation.Z - DistanceBillboard.WorldLocation.Z;
			if(CurrentDistance <= MinDistanceToPlayer)
			{
				CurrentClosestPlayer = Player;
				MinDistanceToPlayer = CurrentDistance;
			}
		}
		
		float TargetSpeed = Math::GetMappedRangeValueClamped(FVector2D(RubberbandMinDistanceToPlayer, RubberbandMaxDistanceToPlayer),FVector2D(RubberbandMinSpeed,RubberbandMaxSpeed),MinDistanceToPlayer);	

		Print(""+ ActorLocation);

		AccSpeed.AccelerateTo(TargetSpeed, 4.0, DeltaSeconds);

		if(CurrentClosestPlayer == nullptr)
			TargetSpeed = 0.0;
			AccSpeed.AccelerateTo(TargetSpeed, -1.0, DeltaSeconds);

		AddActorLocalOffset(FVector(0,0, AccSpeed.Value * DeltaSeconds));

		if(PostProcessMaterialDynamic != nullptr)
		{
			FVector EdgeLocation = DistanceBillboard.GetWorldLocation();
			FVector EdgeDirection = DistanceBillboard.GetUpVector();
			float Radius = 100000;

			PostProcessMaterialDynamic.SetScalarParameterValue(n"whitespaceData_Radius2", Radius - InAnimationTime * 3000);
			PostProcessMaterialDynamic.SetVectorParameterValue(n"whitespaceData_Center2", FLinearColor(EdgeLocation - EdgeDirection * Radius));

			FVector EdgeLocationLocal = FantasyRoot.WorldTransform.InverseTransformPosition(EdgeLocation);
			FVector EdgeDirectionLocal = FantasyRoot.WorldTransform.InverseTransformVector(EdgeDirection);
			EdgeLocation = ScifiRoot.WorldTransform.TransformPosition(EdgeLocationLocal);
			EdgeDirection = ScifiRoot.WorldTransform.TransformVector(EdgeDirectionLocal);
			
			PostProcessMaterialDynamic.SetScalarParameterValue(n"whitespaceData_Radius", Radius - InAnimationTime * 3000);
			PostProcessMaterialDynamic.SetVectorParameterValue(n"whitespaceData_Center", FLinearColor(EdgeLocation - EdgeDirection * Radius));
		}
	}

	UFUNCTION(BlueprintCallable)
	void Disable()
	{
		SetActorTickEnabled(false);

		USoftSplitChaseGlitchEventHandler::Trigger_Stop(this);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ClearRespawnPointOverride(this);
			UPlayerHealthSettings::ClearBlockRespawnWhenNoRespawnPointsEnabled(Player, this);
		}
	}

	UFUNCTION(BlueprintCallable)
	void Completed()
	{
		SetActorLocation(CompletedPosition.ActorLocation);
	}

	UFUNCTION(BlueprintCallable)
	void Activate()
	{
		SetActorTickEnabled(true);

		USoftSplitChaseGlitchEventHandler::Trigger_Started(this);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ResetStickyRespawnPoints();
			UPlayerHealthSettings::SetBlockRespawnWhenNoRespawnPointsEnabled(Player, true, this);

			FOnRespawnOverride RespawnOverride;
			RespawnOverride.BindUFunction(this, n"HandleRespawn");
			Player.ApplyRespawnPointOverrideDelegate(this, RespawnOverride, EInstigatePriority::High);
		}
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutResult)
	{
		// Find the closest respawn point we've marked to the _other_ player
		float ClosestDistance = MAX_flt;
		ERespawnPointPriority Priority = ERespawnPointPriority::Lowest;
		ARespawnPoint ClosestRespawnPoint = nullptr;
		FTransform ClosestPosition;

		float DisableHeight = DistanceBillboard.WorldLocation.Z + DisableRespawnPointDistance;

		auto Manager = ASoftSplitManager::GetSoftSplitManger();
		FVector OtherPlayerLocation = Manager.Position_Convert(
			Player.OtherPlayer.ActorLocation,
			Manager.GetSplitForPlayer(Player.OtherPlayer),
			Manager.GetSplitForPlayer(Player),
		);

		for (ARespawnPoint RespawnPoint : RespawnPointsToDisable)
		{
			if (int(RespawnPoint.RespawnPriority) < int(Priority))
				continue;

			if (Player.IsMio() && !RespawnPoint.bCanMioUse)
				continue;
			if (Player.IsZoe() && !RespawnPoint.bCanZoeUse)
				continue;
			if (!RespawnPoint.IsValidToRespawn(Player))
				continue;

			FTransform Position = RespawnPoint.GetPositionForPlayer(Player);
			if (RespawnPoint.GetPositionForPlayer(Player).Location.Z < DisableHeight)
				continue;

			if (int(RespawnPoint.RespawnPriority) > int(Priority))
			{
				// Higher priority checkpoint, reset the current
				Priority = RespawnPoint.RespawnPriority;
				ClosestRespawnPoint = nullptr;
				ClosestDistance = MAX_flt;
			}

			float Distance = Position.GetLocation().DistSquared(OtherPlayerLocation);
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestRespawnPoint = RespawnPoint;
				ClosestPosition = Position;
			}
		}

		if (ClosestRespawnPoint != nullptr)
		{
			OutResult.RespawnPoint = ClosestRespawnPoint;
			OutResult.RespawnRelativeTo = ClosestRespawnPoint.RootComponent;
			OutResult.RespawnTransform = ClosestRespawnPoint.GetRelativePositionForPlayer(Player);
			return true;
		}

		return false;
	}
};

UCLASS(Abstract)
class USoftSplitChaseGlitchEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Started() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Stop() {}

};