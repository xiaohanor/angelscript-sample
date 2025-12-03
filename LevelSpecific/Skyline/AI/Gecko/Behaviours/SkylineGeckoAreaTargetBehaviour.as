class USkylineGeckoAreaTargetBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	bool bEntered;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		auto Area = USkylineGeckoAreaPlayerComponent::GetOrCreate(Game::Mio);
		Area.OnEnterArea.AddUFunction(this, n"OnEnterArea");
	}

	UFUNCTION()
	private void OnEnterArea()
	{
		bEntered = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!bEntered)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TargetComp.SetTarget(nullptr);
		bEntered = false;
		DeactivateBehaviour();
	}
}