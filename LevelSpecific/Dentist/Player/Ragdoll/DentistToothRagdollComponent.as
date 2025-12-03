struct FDentistToothRagdollImpact
{
	AActor Obstacle;
	float Time;
	FVector Impulse;
};

UCLASS(Abstract)
class UDentistToothRagdollComponent : UActorComponent
{
	private AHazePlayerCharacter Player;
	bool bShouldRagdoll = false;
	bool bIsRagdolling = false;
	float LastHitTime = -1;

	FVector AngularVelocity;
	TInstigated<bool> bAllowAirMovement;
	default bAllowAirMovement.DefaultValue = true;

	UDentistToothRagdollSettings Settings;

	private TArray<FDentistToothRagdollImpact> Impacts;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		auto HitResponseComp = UDentistToothImpulseResponseComponent::Get(Player);
		HitResponseComp.OnImpulseFromObstacle.AddUFunction(this, n"OnImpulseFromObstacle");

		Settings = UDentistToothRagdollSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(int i = Impacts.Num() - 1; i >= 0; i--)
		{
			if(Time::GetGameTimeSince(Impacts[i].Time) > 0.5)
				Impacts.RemoveAtSwap(i);
		}
	}

	UFUNCTION()
	private void OnImpulseFromObstacle(AActor Obstacle, FVector Impulse, FDentistToothApplyRagdollSettings RagdollSettings)
	{
		int ImpactIndex = FindImpact(Obstacle);
		if(ImpactIndex >= 0)
		{
			FVector DeltaImpulse = Impulse - Impacts[ImpactIndex].Impulse;
			if(!DeltaImpulse.IsNearlyZero())
			{
				Player.AddMovementImpulse(DeltaImpulse);
				Impacts[ImpactIndex].Impulse = Impulse;
			}
		}
		else
		{
			Player.AddMovementImpulse(Impulse);
			FDentistToothRagdollImpact Impact;
			Impact.Obstacle = Obstacle;
			Impact.Impulse = Impulse;
			Impact.Time = Time::GameTimeSeconds;
			Impacts.Add(Impact);
		}

		
		if(!RagdollSettings.bApplyRagdoll)
			return;
		
		bShouldRagdoll = true;

		LastHitTime = Time::GameTimeSeconds;

		const FVector RotationalImpulse = Impulse * RagdollSettings.AngularImpulseMultiplier;
		AddRotationalImpulse(RotationalImpulse);

		FDentistToothRagdollOnImpulseFromObstacleEventData EventData;
		EventData.Obstacle = Obstacle;
		EventData.Impulse = Impulse;
		UDentistToothEventHandler::Trigger_OnImpulseFromObstacle(Player, EventData);
	}

	void AddRotationalImpulse(FVector Impulse)
	{
		FVector Right = -FVector::UpVector.CrossProduct(Impulse).GetSafeNormal();
		AngularVelocity += Right * Impulse.Size();
	}

	bool ShouldDoRagdollMovement() const
	{
		if(!bIsRagdolling)
			return false;

		return true;
	}

	int FindImpact(AActor Obstacle) const
	{
		for(int i = 0; i < Impacts.Num(); i++)
		{
			if(Impacts[i].Obstacle == Obstacle)
				return i;
		}

		return -1;
	}
};