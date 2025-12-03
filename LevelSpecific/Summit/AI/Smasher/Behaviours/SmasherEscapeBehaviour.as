class USummitSmasherEscapeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USummitMeltComponent MeltComp;

	bool bExiting;
	float CompleteTime; 
	UAnimInstanceAIBase AnimInstance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MeltComp = USummitMeltComponent::GetOrCreate(Owner);
		AnimInstance = Cast<UAnimInstanceAIBase>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!MeltComp.bMelted)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > CompleteTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		bExiting = false;
		CompleteTime = BIG_NUMBER;
		AnimComp.RequestFeature(SummitSmasherFeatureTag::Melted, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazeActor EscapeFrom = Game::Zoe;
		DestinationComp.RotateTowards(EscapeFrom.ActorLocation);

		if (!MeltComp.bMelted && !bExiting)
		{
			// We're back in business!
			bExiting = true;
			AnimComp.RequestSubFeature(SubTagSmasherMelted::Exit, this);
			CompleteTime = ActiveDuration + 0.5;
			UAnimSequence Anim = AnimInstance.GetRequestedAnimation(SummitSmasherFeatureTag::Melted, SubTagSmasherMelted::Exit);
			if (Anim != nullptr)
				CompleteTime = ActiveDuration + Anim.ScaledPlayLength;
		}
		if (bExiting && MeltComp.bMelted)
		{
			// Oh noes, we got smacked down while recovering
			bExiting = false;
			AnimComp.RequestSubFeature(SubTagSmasherMelted::Enter, this);
			CompleteTime = BIG_NUMBER;
		}
	}
}