class USummitKnightScrapeBladeThroughGroundLeftAnimNotify : UAnimNotifyState
{
#if EDITOR
	default NotifyColor = FColor(180, 180, 100);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Scrape left blade through ground";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp == nullptr)
			return false;
		USummitKnightBladeComponent Blade = SummitKnightBlade::GetLeft(MeshComp.Owner);
		if (Blade == nullptr)
			return false;
		USummitKnightComponent KnightComp = USummitKnightComponent::Get(MeshComp.Owner);
		if (KnightComp == nullptr)
			return false;

		//USummitKnightEventHandler::Trigger_OnScrapeBladeThroughGround(Cast<AHazeActor>(Blade.Owner), FSummitKnightBladeImpactParams(Blade, KnightComp, TotalDuration));	
		return true;	
	}
}

class USummitKnightScrapeBladeThroughGroundRightAnimNotify : UAnimNotifyState
{
#if EDITOR
	default NotifyColor = FColor(180, 100, 180);
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Scrape right blade through ground";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp == nullptr)
			return false;
		USummitKnightBladeComponent Blade = SummitKnightBlade::GetRight(MeshComp.Owner);
		if (Blade == nullptr)
			return false;
		USummitKnightComponent KnightComp = USummitKnightComponent::Get(MeshComp.Owner);
		if (KnightComp == nullptr)
			return false;

//		USummitKnightEventHandler::Trigger_OnScrapeBladeThroughGround(Cast<AHazeActor>(Blade.Owner), FSummitKnightBladeImpactParams(Blade, KnightComp, TotalDuration));	
		return true;	
	}
}
