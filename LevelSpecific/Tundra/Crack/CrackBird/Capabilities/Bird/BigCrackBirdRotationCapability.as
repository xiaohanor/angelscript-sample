class UBigCrackBirdRotationCapability : UBigCrackBirdBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AHazePlayerCharacter CurrentLookedAtPlayer;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Bird.IsPickedUp())
			return false;
		
		if(Bird.CurrentNest == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Bird.IsPickedUp())
			return true;

		if(Bird.CurrentNest == nullptr)
			return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Bird.IsPickupStarted())
		{
			Bird.bIsRotating = true;
			const FQuat WantedRotation = FQuat::MakeFromZX(FVector::UpVector, (Bird.InteractingPlayer.ActorLocation - Owner.ActorLocation).GetSafeNormal());
			float AngleDiff = Math::Abs(WantedRotation.ForwardVector.GetAngleDegreesTo(Owner.ActorQuat.ForwardVector));
			Bird.bIsRotating = AngleDiff > 1;

			Owner.SetActorRotation(Math::QInterpConstantTo(
				Owner.ActorQuat,
				WantedRotation,
				DeltaTime,
				Bird.RotationSpeed * 2));
				
			return;
		}

		//Look at player
		float DistToClosestPlayer = 0;
		AHazePlayerCharacter ClosestPlayer = GetClosestPlayer(Owner.ActorLocation, DistToClosestPlayer);

		if(ClosestPlayer != nullptr && DistToClosestPlayer <= Bird.ReactRange && !Bird.bIsEgg)
		{
			if(CurrentLookedAtPlayer != nullptr && !IsStuckInBird(ClosestPlayer.OtherPlayer))
			{
				float DistToOtherPlayer = (ClosestPlayer.OtherPlayer.ActorLocation - Owner.ActorLocation).Size();

				if(DistToOtherPlayer - DistToClosestPlayer > 100)
					CurrentLookedAtPlayer = ClosestPlayer;
			}
			else
			{
				CurrentLookedAtPlayer = ClosestPlayer;
			}

			Bird.bIsRotating = true;
			const FQuat WantedRotation = FQuat::MakeFromZX(FVector::UpVector, (CurrentLookedAtPlayer.ActorLocation - Owner.ActorLocation).GetSafeNormal());
			float AngleDiff = Math::Abs(WantedRotation.ForwardVector.GetAngleDegreesTo(Owner.ActorQuat.ForwardVector));
			Bird.bIsRotating = AngleDiff > 1;

			Owner.SetActorRotation(Math::QInterpConstantTo(
				Owner.ActorQuat,
				WantedRotation,
				DeltaTime,
				Bird.RotationSpeed));
		}
		else
		{
			CurrentLookedAtPlayer = nullptr;
			Bird.bIsRotating = false;
			FQuat HorizontalRotation = FQuat::MakeFromZX(Bird.CurrentNest.ActorUpVector, Owner.ActorForwardVector);
			Bird.SetActorRotation(Math::QInterpConstantTo(
				Owner.ActorQuat,
				HorizontalRotation,
				DeltaTime,
				Bird.RotationSpeed));
		}
	}

	AHazePlayerCharacter GetClosestPlayer(FVector Location, float&out OutDistance) const
	{
		AHazePlayerCharacter ClosestPlayer = nullptr;
		float ClosestDistance = BIG_NUMBER;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(IsStuckInBird(Player))
				continue;

			const float Distance = Location.Distance(Player.ActorLocation);
			if(Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestPlayer = Player;
			}
		}

		return ClosestPlayer;
	}

	bool IsStuckInBird(AHazePlayerCharacter Player) const
	{
		UCrackBirdPlayerStuckComponent PlayerStuckComp = UCrackBirdPlayerStuckComponent::Get(Player);
		if(PlayerStuckComp == nullptr)
			return false;

		return PlayerStuckComp.IsStuckInBird();
	}
};