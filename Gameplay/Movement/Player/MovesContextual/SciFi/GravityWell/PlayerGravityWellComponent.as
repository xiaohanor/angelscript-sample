
struct FPlayerGravityWellComponentInternalWellData
{
	FInstigator Instigator;
	AGravityWell Well;
}

class UPlayerGravityWellComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	bool bIsLaunching = false;

	UPROPERTY(BlueprintReadOnly)
	FVector GravityWellMovementDirection = FVector::ZeroVector;

	UPlayerGravityWellSettings Settings;
	TArray<AGravityWell> NearbyGravityWells;
	protected TArray<FPlayerGravityWellComponentInternalWellData> InteralActiveGravityWells;

	AHazePlayerCharacter OwningPlayer;
	EPlayerGravityWellState CurrentState = EPlayerGravityWellState::Movement;
	AGravityWell GuidedEnterWell;
	FPlayerGravityWellGuidanceActivationParams GuidanceSettings;

	private float InternalDistanceAlongSpline = 0.0;
	private uint DistanceAlongSplineFrameUpdate = 0;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		Settings = UPlayerGravityWellSettings::GetSettings(OwningPlayer);
	}

	void AddNearbyGravityWell(AGravityWell GravityWell)
	{
		NearbyGravityWells.AddUnique(GravityWell);
	}

	void RemoveNearbyGravityWell(AGravityWell GravityWell)
	{
		NearbyGravityWells.Remove(GravityWell);
	}

	AGravityWell GetValidNearbyGravityWell() const
	{
		if(GuidedEnterWell != nullptr)
			return GuidedEnterWell;

		for (AGravityWell GravityWell : NearbyGravityWells)
		{
			if (!GravityWell.bEnabled)
				continue;
			
			if (!GravityWell.IsWorldLocationInsideWell(OwningPlayer.ActorCenterLocation))
				continue;

			return GravityWell;
		}
		return nullptr;
	}

	void ActivateGravityWell(FPlayerGravityWellActivationParams ActivationParams, FInstigator Instigator)
	{
		for(int i = 0; i < InteralActiveGravityWells.Num(); ++i)
		{
			if(InteralActiveGravityWells[i].Instigator == Instigator)
			{
				// Keep order
				InteralActiveGravityWells.RemoveAt(i);
				break;
			}
		}

		FPlayerGravityWellComponentInternalWellData NewIndex;
		NewIndex.Instigator = Instigator;
		NewIndex.Well = ActivationParams.GravityWell;
		InteralActiveGravityWells.Add(NewIndex);

		GuidedEnterWell = nullptr;
	}

	void ClearGravityWell(FInstigator Instigator)
	{
		for(int i = 0; i < InteralActiveGravityWells.Num(); ++i)
		{
			if(InteralActiveGravityWells[i].Instigator == Instigator)
			{
				// Keep order
				InteralActiveGravityWells.RemoveAt(i);
				break;
			}
		}
	}

	void ForceClearGravityWell()
	{
		InteralActiveGravityWells.Empty();
	}

	AGravityWell GetActiveGravityWell() const property
	{
		if(InteralActiveGravityWells.Num() == 0)
			return nullptr;

		return InteralActiveGravityWells[InteralActiveGravityWells.Num() - 1].Well;
	}

	float GetDistanceAlongSpline() const property
	{
		return InternalDistanceAlongSpline;
	}

	void UpdateDistanceAlongSpline(float NewDistance)
	{
		InternalDistanceAlongSpline = NewDistance;
		DistanceAlongSplineFrameUpdate = Time::FrameNumber;
	}

	uint GetLastUpdatedDistanceFrameNumber() const
	{
		return DistanceAlongSplineFrameUpdate;
	}
}

enum EPlayerGravityWellState
{
	GuidedEntering,
	Movement,
	Eject
}