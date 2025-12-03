class UScorpionSiegeOperatorFindWeaponBehaviour : UBasicBehaviour
{
	UScorpionSiegeOperatorOperationComponent OperationComp;
	AScorpionSiegeOperator Operator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		OperationComp = UScorpionSiegeOperatorOperationComponent::Get(Owner);
		Operator = Cast<AScorpionSiegeOperator>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(OperationComp.TargetWeapon != nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(OperationComp.TargetWeapon != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UHazeTeam WeaponTeam = HazeTeam::GetTeam(ScorpionSiegeTeams::WeaponTeam);
		if(WeaponTeam == nullptr) return;
		
		float ClosestDistSqr = BIG_NUMBER;
		AScorpionSiegeWeapon Target = nullptr;

		for(AHazeActor Actor: WeaponTeam.GetMembers())
		{
			if (Actor == nullptr)
				continue;
			auto Weapon = Cast<AScorpionSiegeWeapon>(Actor);
			if(!Weapon.Manager.CanApproach()) continue;

			float DistSqr = Owner.FocusLocation.DistSquared(Actor.FocusLocation);
			if (DistSqr >= ClosestDistSqr) continue;

			ClosestDistSqr = DistSqr;
			Target = Weapon;
		}		
		
		if(Target != nullptr)
		{
			Target.Manager.Approach(Operator);
		}		
	}
}