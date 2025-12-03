//Break Ice Setup Phase (Phase01)
class UTundraBossBreakIceSetupPhase : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossBreakIceSetupPhase";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto BossSetup = Cast<ATundraBossSetup>(MeshComp.GetOwner());
		if(BossSetup == nullptr)
			return false;

		BossSetup.OnTundraBossBrokeFloor.Broadcast(BossSetup.FloorIndexToBreak);
		return true;
	}
}


class UTundraBossSmashAttackSetupPhase : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossSmashAttackSetupPhase";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto BossSetup = Cast<ATundraBossSetup>(MeshComp.GetOwner());
		if(BossSetup == nullptr)
			return false;

		//Broadcast here
		BossSetup.OnTundraBossSetupSmashAttackImpact.Broadcast();
		return true;
	}
}

class UTundraBossClawAttack01SetupPhase : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossClawAttack01SetupPhase";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto BossSetup = Cast<ATundraBossSetup>(MeshComp.GetOwner());
		if(BossSetup == nullptr)
			return false;

		//Broadcast here
		BossSetup.OnTundraBossSetupClawAttack01Impact.Broadcast();
		return true;
	}
}

class UTundraBossClawAttack02SetupPhase : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossClawAttack02SetupPhase";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto BossSetup = Cast<ATundraBossSetup>(MeshComp.GetOwner());
		if(BossSetup == nullptr)
			return false;

		//Broadcast here
		BossSetup.OnTundraBossSetupClawAttack02Impact.Broadcast();
		return true;
	}
}

class UTundraBossBreakFromUnderIce : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "TundraBossBreakFromUnderIce";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto BossSetup = Cast<ATundraBossSetup>(MeshComp.GetOwner());
		if(BossSetup == nullptr)
			return false;

		BossSetup.OnTundraBossSetupBrokeIceFromUnderIce.Broadcast(BossSetup.FloorIndexToBreak);
		return true;
	}
}