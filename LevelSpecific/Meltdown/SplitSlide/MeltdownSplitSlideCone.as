UCLASS(Abstract)
class UMeltdownSplitSlideConeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit() {}
}

class AMeltdownSplitSlideCone : AWorldLinkDoubleActor
{
	bool bActivated = false;

	const float LaunchUpwardsVelocity = 1500.0;
	const float HorizontalVelocity = 1000.0;
	const float Gravity = -2000.0;
	const float LaunchDuration = 5.0;
	const float RotationSpeed = 180.0;

	float UpwardVelocity = LaunchUpwardsVelocity;
	float LaunchTimeStamp;
	FVector LaunchDirection;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActivated)
		{
			UpwardVelocity += Gravity * DeltaSeconds;
			FVector DeltaMove = FVector::UpVector * UpwardVelocity * DeltaSeconds;
			DeltaMove += LaunchDirection * HorizontalVelocity * DeltaSeconds;

			FVector Location = ActorLocation + DeltaMove;

			FVector RightVector = LaunchDirection.CrossProduct(FVector::UpVector);
			FQuat AddedQuat = FQuat(RightVector, Math::DegreesToRadians(RotationSpeed * DeltaSeconds));
			FQuat ModifiedQuat = FQuat::ApplyDelta(ActorQuat, AddedQuat);

			SetActorLocationAndRotation(Location, ModifiedQuat);

			if (Time::GameTimeSeconds > LaunchTimeStamp + LaunchDuration)
				AddActorDisable(this);
		}

		else
		{
			for (auto Player : Game::Players)
			{
				if (Player.GetDistanceTo(this) < 300.0)
					Activate(Player);
			}
		}
	}

	private void Activate(AHazePlayerCharacter ImpactingPlayer)
	{
		if (bActivated)
			return;

		UMeltdownSplitSlideConeEventHandler::Trigger_OnHit(this);

		LaunchTimeStamp = Time::GameTimeSeconds;
		LaunchDirection = FRotator::MakeFromZX(FVector::UpVector, (ActorLocation - ImpactingPlayer.ActorLocation).GetSafeNormal()).ForwardVector;

		bActivated = true;
	}
};