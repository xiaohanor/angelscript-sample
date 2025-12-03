//Claw Attack Right Paw
class UTundraBossClawAttackRightPaw : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossClawAttackRightPaw";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto ATundraBoss = Cast<ATundraBoss>(MeshComp.GetOwner());
		if(ATundraBoss == nullptr)
			return false;

		ATundraBoss.SpawnClawAttackRightPaw.Broadcast();
		return true;
	}
}

//Claw Attack Left Paw
class UTundraBossClawAttackLeftPaw : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossClawAttackLeftPaw";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto ATundraBoss = Cast<ATundraBoss>(MeshComp.GetOwner());
		if(ATundraBoss == nullptr)
			return false;

		ATundraBoss.SpawnClawAttackLeftPaw.Broadcast();
		return true;
	}
}

//Ring Of Ice Spikes Spawning
class UTundraBossRingOfIceSpikesSpawning : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossRingOfIceSpikesSpawning";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto ATundraBoss = Cast<ATundraBoss>(MeshComp.GetOwner());
		if(ATundraBoss == nullptr)
			return false;

		ATundraBoss.SpawnRingOfIce.Broadcast();
		return true;
	}
}

//Break Ice
class UTundraBossBreakIce : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossBreakIce";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto ATundraBoss = Cast<ATundraBoss>(MeshComp.GetOwner());
		if(ATundraBoss == nullptr)
			return false;

		ATundraBoss.BreakIce.Broadcast();
		return true;
	}
}

//Close Attack
class UTundraBossCloseAttack : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossCloseAttack";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto ATundraBoss = Cast<ATundraBoss>(MeshComp.GetOwner());
		if(ATundraBoss == nullptr)
			return false;

		ATundraBoss.CloseAttack.Broadcast();
		return true;
	}
}

//FurBall01
class UTundraBossFurBall01 : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossFurBall";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto ATundraBoss = Cast<ATundraBoss>(MeshComp.GetOwner());
		if(ATundraBoss == nullptr)
			return false;

		ATundraBoss.FurBall01.Broadcast();
		return true;
	}
}

//FurBall02
class UTundraBossFurBall02 : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossFurBall";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto ATundraBoss = Cast<ATundraBoss>(MeshComp.GetOwner());
		if(ATundraBoss == nullptr)
			return false;

		ATundraBoss.FurBall02.Broadcast();
		return true;
	}
}

//ChargeAttackCollision
class UTundraBossChargeAttackCollision : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossChargeAttackCollision";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto ATundraBoss = Cast<ATundraBoss>(MeshComp.GetOwner());
		if(ATundraBoss == nullptr)
			return false;

		ATundraBoss.OnChargeKillCollisionActivate.Broadcast();
		return true;
	}
}