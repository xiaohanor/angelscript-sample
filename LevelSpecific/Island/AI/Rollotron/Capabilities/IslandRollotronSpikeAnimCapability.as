// Based on MagnetDroneProcAnimCapability.

namespace SpikeSettings
{
	const int NumSpikes = 8;

	const float AccOutDuration = 0.1;
	const float AccInDuration = 1.0;
	const float MoveOutDist = 50;
}

struct FRollotronSpike
{
	UPoseableMeshComponent Mesh;

	FName SocketName = NAME_None;
	FVector ExposedLocation;
	FVector WithdrawnLocation;
	FHazeAcceleratedFloat AccMove;

	void SnapWithdrawSpike()
	{
		AccMove.SnapTo(0.0);
		Mesh.SetBoneLocationByName(SocketName, WithdrawnLocation, EBoneSpaces::ComponentSpace);
	}
	
	void ExposeSpike(const float DeltaTime, float SpeedFactor)
	{
		const float MoveOutDist = SpikeSettings::MoveOutDist;
		float Duration = SpikeSettings::AccOutDuration;		
		AccMove.AccelerateTo(MoveOutDist, Duration , DeltaTime * SpeedFactor);

		const FRotator LocalRotation = Mesh.GetBoneRotationByName(SocketName, EBoneSpaces::ComponentSpace);
		const FVector MoveToLocation = WithdrawnLocation + (LocalRotation.UpVector * AccMove.Value);
		Mesh.SetBoneLocationByName(SocketName, MoveToLocation, EBoneSpaces::ComponentSpace);
	}

	void WithdrawSpike(const float DeltaTime, float SpeedFactor)
	{
		float Duration = SpikeSettings::AccInDuration;
		AccMove.AccelerateTo(0.0, Duration, DeltaTime * SpeedFactor);

		const FRotator LocalRotation = Mesh.GetBoneRotationByName(SocketName, EBoneSpaces::ComponentSpace);
		const FVector MoveToLocation = WithdrawnLocation + (LocalRotation.UpVector * AccMove.Value);
		Mesh.SetBoneLocationByName(SocketName, MoveToLocation, EBoneSpaces::ComponentSpace);
	}

	void TelegraphSpikes()
	{}
}

class UIslandRollotronSpikeAnimCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 120;
	
	UHazeMovementComponent MoveComp;
	UPoseableMeshComponent Mesh;
	UIslandRollotronSpikeComponent SpikeComp;
	UHazeActorRespawnableComponent RespawnComp;

	USceneComponent PreviousSurfaceComponent;
	FTransform PreviousSurfaceTransform;
	TArray<FRollotronSpike> Spikes;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		Mesh = UPoseableMeshComponent::Get(Owner);
		SpikeComp = UIslandRollotronSpikeComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");

		// Get all Spikes
		if (Mesh != nullptr)
		{
			Spikes.Reserve(SpikeSettings::NumSpikes);
			AddSpike(n"TopFrontSpike");
			AddSpike(n"LeftBackBottomSpike");
			AddSpike(n"LeftFrontBottomSpike");
			AddSpike(n"LeftTopSpike");
			AddSpike(n"RightBackBottomSpike");
			AddSpike(n"RightFrontBottomSpike");
			AddSpike(n"RightTopSpike");
			AddSpike(n"TopBackSpike");

			SnapWithdrawSpikes();
		}
	}

	UFUNCTION()
	private void OnReset()
	{
		if (Mesh != nullptr)
		{
			SnapWithdrawSpikes();
		}
	}

	private void AddSpike(FName BoneName)
	{
		FRollotronSpike Spike;
		Spike.Mesh = Mesh;
		Spike.SocketName = BoneName;
		Spike.ExposedLocation = Mesh.GetBoneLocationByName(Spike.SocketName, EBoneSpaces::ComponentSpace);
		Spike.WithdrawnLocation = Spike.ExposedLocation - (Mesh.GetBoneRotationByName(Spike.SocketName, EBoneSpaces::ComponentSpace).UpVector * SpikeSettings::MoveOutDist);
		Spikes.Add(Spike);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Mesh == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Mesh == nullptr)
			return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
#if EDITOR
		if (bIsTesting)
		{
			TestSpikeToggle(DeltaTime);
			return;
		}
#endif
		
		if (SpikeComp.bIsJumping)
		{
			ExposeSpikes(DeltaTime);
		}
		else if (MoveComp.IsOnWalkableGround())
		{
			WithdrawSpikes(DeltaTime);
		}
	}

	void SnapWithdrawSpikes()
	{
		for (FRollotronSpike& Spike : Spikes)
		{
			Spike.SnapWithdrawSpike();
		}
	}

	void ExposeSpikes(const float DeltaTime)
	{
		const float SpeedFactor = 1.0;
		for (int i = 0; i < Spikes.Num(); i++)
		{
			Spikes[i].ExposeSpike(DeltaTime, SpeedFactor);
		}
	}

	void WithdrawSpikes(const float DeltaTime)
	{
		const float SpeedFactor = 1.0;
		for (int i = 0; i < Spikes.Num(); i++)
		{
			Spikes[i].WithdrawSpike(DeltaTime, SpeedFactor);
		}
	}

#if EDITOR
	bool bIsTesting = false;
	bool bIsExposingSpikes = false;
	UFUNCTION(DevFunction)
	void ToggleSpikes()
	{
		bIsTesting = true;
		bIsExposingSpikes = !bIsExposingSpikes;
	}

	void TestSpikeToggle(const float DeltaTime)
	{
		if (bIsExposingSpikes)
		{
			ExposeSpikes(DeltaTime);
		}
		else
		{
			WithdrawSpikes(DeltaTime);
		}
	}
#endif
}