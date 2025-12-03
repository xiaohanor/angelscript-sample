class UWindArrowFollowBowCapability : UHazeCapability
{
	default DebugCategory = WindArrow::DebugCategory;
    default CapabilityTags.Add(WindArrow::WindArrowTag);

	default TickGroup = EHazeTickGroup::PostWork;

	AWindArrow WindArrow;
	UIceBowPlayerComponent IceBowPlayerComp;
	AHazePlayerCharacter Player;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        WindArrow = Cast<AWindArrow>(Owner);
		Player = WindArrow.Player;
		IceBowPlayerComp = UIceBowPlayerComponent::Get(Player);
    }

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WindArrow.bActive)
			return false;

		if(WindArrow.bIsLaunched)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WindArrow.bActive)
			return true;

		if(WindArrow.bIsLaunched)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UStaticMeshComponent BowMesh = IceBowPlayerComp.IceBowMeshComponent;
		FVector HandLocation = Player.Mesh.GetSocketLocation(n"RightHand");
		FVector BowLocation = BowMesh.WorldLocation - BowMesh.RightVector * 12.0 - BowMesh.ForwardVector * 5.0;
		FVector WorldDeltaBetweenEndAndStart = WindArrow.ActorTransform.TransformVector(WindArrow.EndOfArrow.RelativeLocation);
		WindArrow.ActorLocation = HandLocation - WorldDeltaBetweenEndAndStart;
		WindArrow.ActorRotation = FRotator::MakeFromX(BowLocation - HandLocation);
	}
}