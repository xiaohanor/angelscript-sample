UCLASS(Abstract)
class AMoonMarketFlower : AStaticMeshActor
{
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY()
	UMaterialInstance FlowerMat;
    
	UPROPERTY()
	UMaterialInstance ShrivelMat;

	UPROPERTY()
	UNiagaraSystem ShrivelEffect;

	UPROPERTY()
	UNiagaraSystem SparkleEffect;

	UPROPERTY(Category = "Flower Colors")
	FLinearColor BlueTint;
	UPROPERTY(Category = "Flower Colors")
	FLinearColor YellowTint;

	UPROPERTY(Category = "Flower Emissive Colors")
	FLinearColor EmissiveBlueTint;
	UPROPERTY(Category = "Flower Emissive Colors")
	FLinearColor EmissiveYellowTint;

	UPROPERTY()
	const float FlowerSpawnScaleSpringStiffness = 100;

	UPROPERTY()
	const float FlowerSpawnScaleSpringDamping = 0.5;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UMaterialInstanceDynamic DynamicMat;

	UPROPERTY()
	TArray<UStaticMesh> FlowerMeshes;

	float SpawnTime;

	bool bIsShriveling = false;

	FHazeAcceleratedVector Scale;
	FVector TargetScale;

	TOptional<int> BelongingCircleIndex;

	float DefaultEmissiveAlpha = 0.04;
	FHazeAcceleratedFloat CurrentEmissiveAlpha;
	bool bPieceActivated = false;
	bool bCorrectColor = false;

	// EHazePlayer Player;
	

	FMoonMarketFlowerPuzzleOverlapData InternalData;


    void CreateFlower(FMoonMarketFlowerPuzzleOverlapData Data, const FMoonMarketFlowerPuzzleOverlapResult& OverlapResult)
    {
		UStaticMesh FlowerMesh;
		FlowerMesh = FlowerMeshes[Math::RandRange(0, FlowerMeshes.Num()-1)];
		InternalData = Data;

		// Player = Data.Player;
		Scale.Value = FVector::ZeroVector;
		SpawnTime = Time::GameTimeSeconds;
		StaticMeshComponent.SetStaticMesh(FlowerMesh);

		SetActorRotation(FQuat(FVector::UpVector, Math::RandRange(0, PI * 2)));
        TargetScale = FVector::OneVector * Math::RandRange(0.25, 0.4);
		
		SetLifeSpan(OverlapResult.bSuccesfulPlacement ? MAX_flt : FlowerPuzzle::FlowerUnhealthyLifeTime);

		if(OverlapResult.bSuccesfulPlacement)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(SparkleEffect, ActorLocation, ActorRotation, FVector::OneVector * 0.1);
		}

		bCorrectColor = OverlapResult.bCorrectColor;

		if(OverlapResult.OverlappedCircleIndex.IsSet())
			BelongingCircleIndex.Set(OverlapResult.OverlappedCircleIndex.Value);

		DynamicMat = Material::CreateDynamicMaterialInstance(this, FlowerMat);

		if (Data.Type == EMoonMarketFlowerHatType::Blue)
		
			DynamicMat.SetVectorParameterValue(n"Tint", BlueTint);
		else
			DynamicMat.SetVectorParameterValue(n"Tint", YellowTint);

		StaticMeshComponent.SetMaterial(0, DynamicMat);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bDisableTick = true;

		const float TargetAlpha = bPieceActivated && bCorrectColor ? 1 : DefaultEmissiveAlpha;
		if(Math::Abs(CurrentEmissiveAlpha.Value - TargetAlpha) > 0.05)
		{
			bDisableTick = false;
			CurrentEmissiveAlpha.AccelerateTo(TargetAlpha, 1, DeltaSeconds);

			if (InternalData.Type == EMoonMarketFlowerHatType::Yellow)
				DynamicMat.SetVectorParameterValue(n"EmissiveTint", EmissiveYellowTint * CurrentEmissiveAlpha.Value);
			else
				DynamicMat.SetVectorParameterValue(n"EmissiveTint", EmissiveBlueTint * CurrentEmissiveAlpha.Value);
		}

		const float TimeSinceSpawn = Time::GameTimeSeconds - SpawnTime;
		const float TimeLeft = LifeSpan - TimeSinceSpawn;
		if(Math::Abs(Scale.Value.X - TargetScale.X) > KINDA_SMALL_NUMBER)
		{
			bDisableTick = false;
			Scale.SpringTo(TargetScale, FlowerSpawnScaleSpringStiffness, FlowerSpawnScaleSpringDamping, DeltaSeconds);
			SetActorScale3D(Scale.Value);
		}

		if(Math::IsFinite(LifeSpan))
		{
			bDisableTick = false;

			if(!bIsShriveling)
			{
				if(TimeLeft <= FlowerPuzzle::FlowerWitherLifeTime)
				{
					Niagara::SpawnOneShotNiagaraSystemAtLocation(ShrivelEffect, ActorLocation);
					bIsShriveling = true;
					StaticMeshComponent.SetMaterial(0, ShrivelMat);
				}
			}
			else
			{
				float ScaleMultiplier = TimeLeft / FlowerPuzzle::FlowerWitherLifeTime;
				ScaleMultiplier = Math::Clamp(ScaleMultiplier, 0, 1);

				SetActorScale3D(Scale.Value * ScaleMultiplier);
			}
		}
		
		if(bDisableTick)
		{
			SetActorTickEnabled(false);
		}

		// #if EDITOR
		// TickTemporalLog();
		// #endif
	}

	void KillFlower()
	{
		SetLifeSpan(0);
		SetActorTickEnabled(true);
	}

	void TickTemporalLog()
	{
		// if(!BelongingCircleIndex.IsSet())
		// 	return;

		// FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		// TemporalLog.Point("CircleLocation", BelongingCircleIndex.Value.Center);
	}

	void SetPieceActivated(bool bActive)
	{
		bPieceActivated = bActive;
		SetActorTickEnabled(true);
	}
};