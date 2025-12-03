class UIslandOverseerDoorCutHeadResistAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(150, 0, 0);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Resist";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		UIslandOverseerDoorComponent DoorComp = UIslandOverseerDoorComponent::GetOrCreate(MeshComp.Owner);
		DoorComp.bResist = true;
		return true;
	}
}

class UIslandOverseerDoorCutHeadCutAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(200, 0, 0);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Cut";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		UIslandOverseerDoorComponent DoorComp = UIslandOverseerDoorComponent::GetOrCreate(MeshComp.Owner);
		return true;
	}
}

class UIslandOverseerDoorCutHeadEndAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(250, 0, 0);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "End";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		UIslandOverseerDoorComponent DoorComp = UIslandOverseerDoorComponent::GetOrCreate(MeshComp.Owner);
		return true;
	}
}

class UIslandOverseerDoorCutHeadLeftEyeExplodeAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(0, 250, 250);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "LeftEyeExplode";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		UIslandOverseerDoorComponent DoorComp = UIslandOverseerDoorComponent::GetOrCreate(MeshComp.Owner);
		DoorComp.LeftEyeExplode();
		return true;
	}
}

class UIslandOverseerDoorCutHeadRightEyeExplodeAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(0, 0, 250);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "RightEyeExplode";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		UIslandOverseerDoorComponent DoorComp = UIslandOverseerDoorComponent::GetOrCreate(MeshComp.Owner);
		DoorComp.RightEyeExplode();
		return true;
	}
}

class UIslandOverseerDoorCutHeadHeadImpactAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(250, 0, 250);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "HeadImpact";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		UIslandOverseerDoorComponent DoorComp = UIslandOverseerDoorComponent::GetOrCreate(MeshComp.Owner);
		DoorComp.HeadImpact();
		return true;
	}
}