/**
 * If this component is in the level, the post process ubershader will always be active.
 * Should only be necessary in rare cases that materials in the level rely on postprocessing.
 */
class UUberPostProcessShaderEnablementComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Player : Game::Players)
		{
			auto PPComp = UPostProcessingComponent::Get(Player);
			if (PPComp != nullptr)
				PPComp.UberShaderEnablement.Apply(true, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Player : Game::Players)
		{
			auto PPComp = UPostProcessingComponent::Get(Player);
			if (PPComp != nullptr)
				PPComp.UberShaderEnablement.Clear(this);
		}
	}
};