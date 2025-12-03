event void FTundraTreeGuardianRangedShootEvent();

class UTundraTreeGuardianRangedShootTargetable : UTargetableComponent
{
	default TargetableCategory = n"RangedShoot";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY()
	FTundraTreeGuardianRangedShootEvent OnHit;

	UPROPERTY()
	float MaxRange = 12000.0;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		FVector PlayerToTargetable = (WorldLocation - Query.PlayerLocation).GetSafeNormal2D();
		auto TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Query.Player);
		
		FVector PlayerToProjectile = (TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.WorldLocation - Query.PlayerLocation).GetSafeNormal2D();
		float Degrees = PlayerToTargetable.GetAngleDegreesTo(PlayerToProjectile);
		auto Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Query.Player);
		if(Degrees > Settings.MaxAngleToShootTargetableFromPlayerForward)
			return false;

		Targetable::ApplyTargetableRange(Query, MaxRange);
		return true;
	}
}

class UTundraTreeGuardianRangedShootTargetableVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraTreeGuardianRangedShootTargetable;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Targetable = Cast<UTundraTreeGuardianRangedShootTargetable>(Component);
		DrawWireSphere(Targetable.WorldLocation, Targetable.MaxRange, FLinearColor::Red);
	}
}