class USummitKnightJerkStuckBladeLeftAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(100, 180, 100);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Jerk stuck left blade";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp == nullptr)
			return false;
		USummitKnightBladeComponent Blade = SummitKnightBlade::GetLeft(MeshComp.Owner);
		if (Blade == nullptr)
			return false;
		USummitKnightComponent KnightComp = USummitKnightComponent::Get(MeshComp.Owner);
		if (KnightComp == nullptr)
			return false;

		//USummitKnightEventHandler::Trigger_OnJerkStuckBlade(Cast<AHazeActor>(Blade.Owner), FSummitKnightBladeImpactParams(Blade, KnightComp));	
		return true;	
	}
}

class USummitKnightJerkStuckBladeRightAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor(100, 100, 180);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Jerk stuck right blade";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp == nullptr)
			return false;
		USummitKnightBladeComponent Blade = SummitKnightBlade::GetRight(MeshComp.Owner);
		if (Blade == nullptr)
			return false;
		USummitKnightComponent KnightComp = USummitKnightComponent::Get(MeshComp.Owner);
		if (KnightComp == nullptr)
			return false;

//		USummitKnightEventHandler::Trigger_OnJerkStuckBlade(Cast<AHazeActor>(Blade.Owner), FSummitKnightBladeImpactParams(Blade, KnightComp));	
		return true;	
	}
}
