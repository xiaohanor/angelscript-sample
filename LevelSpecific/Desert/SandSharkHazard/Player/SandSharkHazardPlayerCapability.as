struct FHazardSpawnParams
{
	FVector Location;
	FVector Normal;
}

class USandSharkHazardPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(SandSharkHazard::Tags::SandSharkHazard);
	default CapabilityTags.Add(SandSharkHazard::Tags::SandSharkHazardAttack);

	default TickGroup = EHazeTickGroup::Gameplay;

	USandSharkHazardPlayerComponent PlayerComp;
	bool bHasSpawnedShark = false;
	bool bOnSandPreviousFrame = false;
	float TimeWhenHitSand = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USandSharkHazardPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bool bHitSand = IsLandscape(PlayerComp.GetHitUnderPlayer(SandShark::OnSandTraceMaxDistance).Actor);

		if (!bOnSandPreviousFrame && bHitSand)
		{
			TimeWhenHitSand = Time::GetGameTimeSeconds();
		}
		else if (!bOnSandPreviousFrame && !bHitSand)
		{
			TimeWhenHitSand = BIG_NUMBER;
		}

		bOnSandPreviousFrame = bHitSand;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHazardSpawnParams& Params) const
	{
		return false;
		// if (PlayerComp.Player.IsPlayerDead() || PlayerComp.Player.IsPlayerRespawning())
		// 	return false;

		// if (DeactiveDuration < SandSharkHazard::SharkSpawnCooldown)
		// 	return false;

		// auto HitResult = PlayerComp.GetHitUnderPlayer(SandSharkHazard::SandDetectionDistance);
		// bool bHitSand = IsLandscape(HitResult.Actor);

		// if (!bHitSand || Time::GetGameTimeSince(TimeWhenHitSand) < SandSharkHazard::SandHitDelay)
		// 	return false;

		// Params.Location = HitResult.ImpactPoint;
		// Params.Normal = HitResult.Normal;
		// return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PlayerComp.Player.IsPlayerDead() || PlayerComp.Player.IsPlayerRespawning())
			return true;

		bool bHitSand = IsLandscape(PlayerComp.GetHitUnderPlayer(SandSharkHazard::SandDetectionDistance).Actor);

		if (!bHitSand)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHazardSpawnParams Params)
	{
		PlayerComp.bHasTouchedSand = true;
		auto SpawnLocation = Params.Location;

		FVector ToPlayer = PlayerComp.Player.ActorCenterLocation - SpawnLocation;
		FVector SharkUp = ToPlayer.CrossProduct(FVector::RightVector);

		auto SpawnRotation = FRotator::MakeFromXZ(FVector::UpVector, SharkUp);
		auto NewHazard = SpawnActor(PlayerComp.HazardClass,  SpawnLocation + FVector::DownVector * SandSharkHazard::Shark::SpawnDepth, SpawnRotation);
		auto HazardComp = USandSharkHazardComponent::Get(NewHazard);
		HazardComp.TargetPlayer = PlayerComp.Player;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.bHasTouchedSand = false;
	}

	bool IsLandscape(AActor Actor) const
	{
		if (Actor != nullptr)
		{
			auto Landscape = UDesertLandscapeComponent::Get(Actor);
			if(Landscape != nullptr)
				return true;
		}

		return false;
	}
};