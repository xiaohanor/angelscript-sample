class UBigCrackBirdPickedUpCapability : UBigCrackBirdBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	
	float InterpSpeed = 100;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Bird.IsPickedUp())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Bird.IsPickedUp())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(Bird.bNetWasForcedAttach)
		{
			InterpSpeed = 10000;
		}
		else
		{
			InterpSpeed = 100;
		}

		if(Bird.bIsEgg)
		{
			for(auto ListedBird : TListedActors<ABigCrackBird>().Array)
			{
				ListedBird.bEggPickedUp = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Bird.bNetWasForcedAttach = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FQuat WantedRotation = FQuat::MakeFromEuler(FVector::ZeroVector);

		Owner.SetActorRelativeRotation(Math::QInterpConstantTo(
				Owner.ActorRelativeRotation.Quaternion(),
				WantedRotation,
				DeltaTime,
				Bird.RotationSpeed));

		//Smoothly lerps bird to player socket attach
		Owner.SetActorRelativeLocation(Math::VInterpConstantTo(Owner.ActorRelativeLocation, FVector::ZeroVector, DeltaTime, InterpSpeed));
	}
};