UCLASS(Abstract)
class UMoonMarketPlayerFlowerSpawningComponent : UActorComponent
{
	UPROPERTY()
	UHazeComposableSettings FloorMotionSetting;

	UPROPERTY()
	TSubclassOf<AMoonMarketFlower> FlowerClass;

	UPROPERTY()
	UForceFeedbackEffect Rumble;

	UPROPERTY()
	UMaterialInstance FlowerMat;

	UPROPERTY()
	const float DistanceBetweenFlowerSpawns = 20;

	UPROPERTY()
	const float FlowerEraseRadius = 60;

	UPROPERTY()
	const int FlowersPerSpawn = 5;

	UPROPERTY()
	const float FlowerSpawnRadius = 20;

	UPROPERTY()
	const float LocationCorrection = 1.25;

	UPROPERTY()
	const int MaxFlowerGroupDensity = 2;

	UPROPERTY()
	FHazePlaySlotAnimationParams InteractionAnimation;

	UPROPERTY()
	UNiagaraSystem ShrivelEffect;

	UPROPERTY()
	UNiagaraSystem ShrivelEffectSmall;

	UPROPERTY()
	UStaticMesh FlowerMesh;

	private AHazePlayerCharacter Player;

	UInstancedStaticMeshComponent InstancedMeshComponent;
	FFlowerInstanceDataPerComponent SpawnData;
	UMaterialInstanceDynamic DynamicMat;
	TArray<int> PooledIds;

	AMoonMarketNonQuestFlowerPaintingVolume PaintingVolume;
	bool bShowPaintingTutorial = false;
	bool bShowEraseTutorial = false;

	bool bIsDancing = false;

	AMoonMarketFlowerHat Hat;
	bool bPickingUpHat = false;

	uint FlowersSpawned = 0;

	FLinearColor FlowerTint;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		SpawnInstancedStaticMeshComponent(FlowerMesh);
	}

	void SpawnInstancedStaticMeshComponent(UStaticMesh Mesh)
	{
		InstancedMeshComponent = UInstancedStaticMeshComponent::Create(TListedActors<AFlowerCatPuzzle>().Single, FName(f"InstancedMesh{Player.Name}"));
		InstancedMeshComponent.SetStaticMesh(Mesh);
		InstancedMeshComponent.SetAbsolute(true, true, true);
		InstancedMeshComponent.NumCustomDataFloats = 4;
		DynamicMat = Material::CreateDynamicMaterialInstance(TListedActors<AFlowerCatPuzzle>().Single, FlowerMat);
		InstancedMeshComponent.SetMaterial(0, DynamicMat);


		SpawnData = FFlowerInstanceDataPerComponent();
	}

	void SetHat(AMoonMarketFlowerHat _Hat)
	{
		Hat = _Hat;
		bPickingUpHat = true;
		FlowerTint = Hat.FlowerTint;
	}

	void RemoveHat(AMoonMarketFlowerHat _Hat)
	{
		if(Hat == _Hat)
			Hat = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float GameTime = Time::GameTimeSeconds;

		for(int InstanceID = SpawnData.InstanceDatas.Num() - 1; InstanceID >= 0; InstanceID--)
		{
			auto& Instance = SpawnData.InstanceDatas[InstanceID];

			if(Instance.bIsPooled)
				continue;

			if(Instance.bIsWithering)
			{
				if(GameTime > Instance.DeathTime)
				{
					Niagara::SpawnOneShotNiagaraSystemAtLocation(ShrivelEffectSmall, Instance.Transform.Location);
					RemoveInstance(InstanceID);
				}
				else
					SetFlowerDeadTint(InstanceID, Instance.DeathTime - GameTime);
			}
			else 
			{
				//LERP FLOWER SCALE
				if(!Math::IsNearlyEqual(Instance.CurrentSizeMultiplier, 1))
				{
					Instance.CurrentSizeMultiplier = Math::FInterpConstantTo(Instance.CurrentSizeMultiplier, 1, DeltaSeconds, 4);
					Instance.Transform.Scale3D = FVector::OneVector * Instance.CurrentSizeMultiplier * Instance.TargetScale;
					InstancedMeshComponent.UpdateInstanceTransform(InstanceID, Instance.Transform);
				}	

				//LERP FLOWER EMISSIVE
				if(!Math::IsNearlyEqual(Instance.CurrentEmissive, Instance.TargetEmissive))
				{
					Instance.CurrentEmissive = Math::FInterpConstantTo(Instance.CurrentEmissive, Instance.TargetEmissive, DeltaSeconds, 50);
					InstancedMeshComponent.SetCustomDataValue(InstanceID, 0, Instance.CurrentEmissive);
				}
			}
		}
	}

	void SetFlowerTint(TArray<int> Ids)
	{
		for(int InstanceID : Ids)
		{
			InstancedMeshComponent.SetCustomDataValue(InstanceID, 1, Hat.FlowerTint.R);
			InstancedMeshComponent.SetCustomDataValue(InstanceID, 2, Hat.FlowerTint.G);
			InstancedMeshComponent.SetCustomDataValue(InstanceID, 3, Hat.FlowerTint.B);
		}
	}

	void SetFlowerDeadTint(int InstanceID, float TimeLeft)
	{
		FLinearColor DeadTint = FlowerTint * (TimeLeft / FlowerPuzzle::FlowerUnhealthyLifeTime);

		InstancedMeshComponent.SetCustomDataValue(InstanceID, 0, 0);
		InstancedMeshComponent.SetCustomDataValue(InstanceID, 1, DeadTint.R);
		InstancedMeshComponent.SetCustomDataValue(InstanceID, 2, DeadTint.G);
		InstancedMeshComponent.SetCustomDataValue(InstanceID, 3, DeadTint.B);
	}

	void SetFlowersActivated(TArray<int> Ids, bool bShouldActivate)
	{
		float Emissive = bShouldActivate ? 20 : 0;

		for(int InstanceID : Ids)
		{
			SpawnData.InstanceDatas[InstanceID].TargetEmissive = Emissive;
		}
	}

	int AddInstance(FVector Location, bool bSuccesfulPlacement)
	{
		FTransform SpawnTransform;
		SpawnTransform.Location = Location;
		SpawnTransform.Scale3D = FVector::OneVector * Math::RandRange(0.25, 0.4);
		SpawnTransform.Rotation = FQuat(FVector::UpVector, Math::RandRange(0, PI * 2));

		int InstanceID = -1;
		
		while(!PooledIds.IsEmpty() && InstanceID == -1)
		{
			if(!SpawnData.InstanceDatas[PooledIds[0]].bIsPooled)
			{
				PooledIds.RemoveAt(0);
				continue;
			}

			InstanceID = PooledIds[0];

			SpawnData.InstanceDatas[InstanceID].bIsPooled = false;
			SpawnData.InstanceDatas[InstanceID].Transform = SpawnTransform;
			PooledIds.RemoveAt(0);
			InstancedMeshComponent.SetCustomDataValue(InstanceID, 0, 0);
			InstancedMeshComponent.UpdateInstanceTransform(InstanceID, SpawnTransform);
		}

		if(InstanceID == -1)
		{
			InstanceID = InstancedMeshComponent.AddInstance(SpawnTransform, true);
		}
		

		if(!SpawnData.InstanceDatas.IsValidIndex(InstanceID))
		{
			SpawnData.InstanceDatas.Add(FFlowerInstanceData(SpawnTransform, bSuccesfulPlacement));
			check(SpawnData.InstanceDatas.Num() == InstancedMeshComponent.InstanceCount);
		}

		if(!bSuccesfulPlacement)
			UMoonMarketFlowerHatEventHandler::Trigger_OnFlowersWither(Hat, FMoonMarketFlowerHatEffectParams(Player, Location));

		SpawnData.InstanceDatas[InstanceID].DeathTime = bSuccesfulPlacement ? MAX_flt : Time::GameTimeSeconds + FlowerPuzzle::FlowerUnhealthyLifeTime;
		SpawnData.InstanceDatas[InstanceID].TargetScale = SpawnTransform.Scale3D.X;
		SpawnData.InstanceDatas[InstanceID].CurrentEmissive = 0;
		SpawnData.InstanceDatas[InstanceID].TargetEmissive = 0;
		SpawnData.InstanceDatas[InstanceID].bIsWithering = !bSuccesfulPlacement;
		return InstanceID;
	}

	void RemoveInstances(TArray<int> InstanceIDs)
	{
		for(int i = 0; i < InstanceIDs.Num(); i++)
			RemoveInstance(InstanceIDs[i]);
	}

	void RemoveInstance(int InstanceID)
	{
		//if(InstancedMeshComponent.RemoveInstance(InstanceID))
		{
			PooledIds.Add(InstanceID);
			FTransform HiddenTransform;
			HiddenTransform.Scale3D = FVector::ZeroVector;
			InstancedMeshComponent.UpdateInstanceTransform(InstanceID, HiddenTransform);
			SpawnData.InstanceDatas[InstanceID].bIsPooled = true;
			//SpawnData.InstanceDatas.RemoveAt(InstanceID);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnFlowers(TArray<FVector> SpawnLocations, FVector OwnerLocation, EMoonMarketFlowerHatType FlowerType)
	{
		FMoonMarketFlowerPuzzleOverlapResult OverlapResult;
		FMoonMarketFlowerPuzzleOverlapData Data;

		Data.FlowerLocation = OwnerLocation;
		Data.Player = Player.Player;
		Data.Type = FlowerType;
		Data.FlowerComp = this;

		if(PaintingVolume != nullptr && PaintingVolume.IsInsidePaintingArea(Player))
		{
			SpawnFlowersInPaintingVolume(SpawnLocations, OverlapResult, Data);
		}
		else
		{
			SpawnFlowersNoPaintingVolume(SpawnLocations, OverlapResult, Data);
		}

		UMoonMarketFlowerHatEventHandler::Trigger_OnFlowersGrow(Hat, FMoonMarketFlowerHatEffectParams(Player, OwnerLocation));
	}

	void SpawnFlowersInPaintingVolume(TArray<FVector> SpawnLocations, FMoonMarketFlowerPuzzleOverlapResult& OverlapResult, FMoonMarketFlowerPuzzleOverlapData& Data)
	{
		OverlapResult.bSuccesfulPlacement = true;
		OverlapResult.bCorrectColor = true;
		
		//Max amount of flowers reached, start reusing the first ones
		if(PaintingVolume.FlowerGroups.Num() >= PaintingVolume.MaxAllowedFlowers)
		{			
			Data.FlowerIds = PaintingVolume.FlowerGroups[0].FlowerIds;
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ShrivelEffect, PaintingVolume.FlowerGroups[0].FlowerLocation);
			RemoveInstances(Data.FlowerIds);

			PaintingVolume.FlowerGroups.RemoveAt(0);
		}
			
		TArray<int> Ids;
		for(int i = 0; i < SpawnLocations.Num(); i++)
		{
			FVector Location = SpawnLocations[i] + Player.ActorLocation;
			Ids.Add(AddInstance(Location, OverlapResult.bSuccesfulPlacement));
		}
		
		SetFlowerTint(Ids);
		Data.FlowerIds = Ids;
		PaintingVolume.FlowerGroups.Add(Data);
	}

	void SpawnFlowersNoPaintingVolume(TArray<FVector> SpawnLocations, FMoonMarketFlowerPuzzleOverlapResult& OverlapResult, FMoonMarketFlowerPuzzleOverlapData& Data)
	{
		if(!TListedActors<AFlowerCatPuzzle>().Single.IsPuzzleSolved())
		{
			TListedActors<AFlowerCatPuzzle>().Single.CheckForOverlap(Data, OverlapResult);
		}
		else
		{
			bShowPaintingTutorial = false;
		}

		if(OverlapResult.bSuccesfulPlacement)
		{
			//Prevent overcrowding of flowers
			if(OverlapResult.OverlappedCircleIndex.IsSet())
			{
				FSplineCircle& Circle = OverlapResult.BelongingPiece.Circles[OverlapResult.OverlappedCircleIndex.Value];

				bool bContainsWrongColor = false;
				for(const auto& FlowerGroup : Circle.FlowerGroups)
				{
					if(FlowerGroup.Type != Data.Type)
					{
						bContainsWrongColor = true;
						break;
					}
				}

				if(bContainsWrongColor || Circle.FlowerGroups.Num() < MaxFlowerGroupDensity)
				{
					TArray<int> Ids = SpawnFlowerInstances(SpawnLocations, OverlapResult);
					Data.FlowerIds = Ids;
					OverlapResult.BelongingPiece.Circles[OverlapResult.OverlappedCircleIndex.Value].AddFlowers(Data);
					OverlapResult.BelongingPiece.UpdateActivatedCirclesAmount();
					
					SetFlowerTint(Ids);

					if(OverlapResult.BelongingPiece.bPieceActivated)
						SetFlowersActivated(Ids, true);
				}
			}
		}
		else
		{
			TArray<int> Ids = SpawnFlowerInstances(SpawnLocations, OverlapResult);
			
			for(int Id : Ids)
				SetFlowerDeadTint(Id, FlowerPuzzle::FlowerUnhealthyLifeTime);
		}
	}

	TArray<int> SpawnFlowerInstances(TArray<FVector> SpawnLocations, FMoonMarketFlowerPuzzleOverlapResult& OverlapResult)
	{
		TArray<int> Ids;

		for(int i = 0; i < SpawnLocations.Num(); i++)
		{
			FVector Location;

			if(OverlapResult.BelongingPiece != nullptr)
				Location = SpawnLocations[i] + (Player.ActorLocation + OverlapResult.BelongingPiece.Circles[OverlapResult.OverlappedCircleIndex.Value].Center) / 2;
			else
				Location = SpawnLocations[i] + Player.ActorLocation;

			int Id = AddInstance(Location, OverlapResult.bSuccesfulPlacement);
			Ids.Add(Id);
		}

		return Ids;
	}

	UFUNCTION(CrumbFunction)
	void CrumbEraseFlowers()
	{
		if(PaintingVolume != nullptr)
			PaintingVolume.EraseFlowers(this, Player, Owner.ActorLocation);
		// else
		// 	TListedActors<AFlowerCatPuzzle>().Single.EraseFlowers(Player.Player, Owner.ActorLocation, FlowerEraseRadius);
	}
};