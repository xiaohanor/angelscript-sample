event void FOnAttackDone();

class AMeltdownBossPhaseThreeHydraHead : AHazeCharacter
{
	AHazePlayerCharacter Player;

	FVector TargetLoc;

	UPROPERTY()
	FOnAttackDone AttackDone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::GetClosestPlayer(ActorLocation);
	}

	UFUNCTION(BlueprintCallable)
	void OrientToTarget()
	{
		SetActorTickEnabled(true);
		TargetLoc = Player.ActorLocation;
		FVector Totarget = (TargetLoc - ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		FQuat TargetRot = Totarget.ToOrientationQuat();
		SetActorRotation(TargetRot);
	}

	UFUNCTION(BlueprintCallable)
	void Retreated()
	{
		AttackDone.Broadcast();
	}
};