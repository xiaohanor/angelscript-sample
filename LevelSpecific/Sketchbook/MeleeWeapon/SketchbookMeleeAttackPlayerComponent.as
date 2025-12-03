struct FSketchbookMeleeAttackData
{
	FVector WeaponLocation;
	FVector AttackDirection;
	AHazePlayerCharacter AttackingPlayer;

	FSketchbookMeleeAttackData(FVector InWeaponLocation, FVector InAttackDirection, AHazePlayerCharacter Player)
	{
		WeaponLocation = InWeaponLocation;
		AttackDirection = InAttackDirection;
		AttackingPlayer = Player;
	}
}

class USketchbookMeleeAttackPlayerComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;
	USketchbookMeleeWeaponPlayerComponent CurrentWeapon;
	FSketchbookMeleeAttackData CurrentAttackData;

	FSketchbookMeleeAnimData AnimData;

	bool bAttackFinished = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	void Attack(FSketchbookMeleeAttackData AttackData)
	{
		bAttackFinished = false;

		CurrentAttackData = AttackData;
		PlayAttackAnimation();
		CurrentWeapon.OnAttack(AttackData);
	}

	void FinishAttack()
	{
		bAttackFinished = true;
	}

	bool CanAttack() const
	{
		return true;
		//return Time::FrameNumber >= AnimData.LastAttackEndFrame;
	}

	void AttackOverlapCheck(FSketchbookMeleeAttackData AttackData, USketchbookMeleeWeaponSettings Settings)
	{
		if(!HasControl())
			return;
		
		//Debug::DrawDebugSphere(AttackData.WeaponLocation, AttackData.WeaponSettings.Radius, Duration = 1);

		FHazeTraceSettings SphereTrace;
		SphereTrace.TraceWithProfile(n"PlayerCharacter");
		SphereTrace.UseSphereShape(Settings.Radius);
		
		TArray<USketchbookMeleeAttackableComponent> AttackableComponents;

		FOverlapResultArray Overlaps = SphereTrace.QueryOverlaps(AttackData.WeaponLocation);
		for(auto Overlap : Overlaps)
		{
			auto AttackableComp = USketchbookMeleeAttackableComponent::Get(Overlap.Actor);
			if(AttackableComp == nullptr)
				continue;

			if(AttackData.AttackDirection.DotProduct((AttackableComp.Owner.ActorLocation - Player.ActorLocation).GetSafeNormal()) < 0)
				continue;

			AttackableComponents.Add(AttackableComp);
		}

		if(!AttackableComponents.IsEmpty())
		{
			// We hit something, broadcast to response components
			CrumbAttackOverlap(AttackData, AttackableComponents);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbAttackOverlap(FSketchbookMeleeAttackData AttackData, TArray<USketchbookMeleeAttackableComponent> AttackableComponents)
	{
		for(USketchbookMeleeAttackableComponent AttackableComponent : AttackableComponents)
		{
			if(!IsValid(AttackableComponent))
				continue;

			AttackableComponent.OnAttacked.Broadcast(AttackData);
		}

		Player.PlayForceFeedback(CurrentWeapon.WeaponSettings.HitForceFeedback, false, false, this);
	}

	void PlayAttackAnimation()
	{
#if !RELEASE
		TEMPORAL_LOG(this, Owner, "Melee").Event("PlayAttackAnimation");
#endif

		if(CurrentWeapon.WeaponSettings.Feature == nullptr)
		{
			devError("No feature assigned to current weapon composable settings file");
			return;
		}

		if(MoveComp.HasGroundContact())
		{
			AnimData.AttackIndex += 1;
			if(AnimData.AttackIndex >= CurrentWeapon.WeaponSettings.Feature.AnimData.AttackSequences[AnimData.SequenceIndex].Sequence.Num())
			{
				AnimData.SequenceIndex = GetNextSequence();
				AnimData.AttackIndex = 0;
				AnimData.BlockMovementDuration = CurrentWeapon.WeaponSettings.Feature.AnimData.AttackSequences[AnimData.SequenceIndex].Sequence[AnimData.AttackIndex].BlockMovementDuration;
				AnimData.BlockAttackDuration = CurrentWeapon.WeaponSettings.Feature.AnimData.AttackSequences[AnimData.SequenceIndex].Sequence[AnimData.AttackIndex].BlockAttackDuration;
			}
		}
		else
		{
			AnimData.BlockMovementDuration = CurrentWeapon.WeaponSettings.Feature.AnimData.AirAttack.BlockMovementDuration;
			AnimData.BlockAttackDuration = CurrentWeapon.WeaponSettings.Feature.AnimData.AirAttack.BlockAttackDuration;
			AnimData.AttackIndex = 0;
			AnimData.SequenceIndex = 0;
		}

		AnimData.bBlockMovement = true;

		Player.SetAnimTrigger(n"Attack");
	}

	int GetNextSequence()
	{
		AnimData.SequenceIndex += 1;
		if(AnimData.SequenceIndex >= CurrentWeapon.WeaponSettings.Feature.AnimData.AttackSequences.Num())
			AnimData.SequenceIndex = 0;

		return AnimData.SequenceIndex;
	}
};