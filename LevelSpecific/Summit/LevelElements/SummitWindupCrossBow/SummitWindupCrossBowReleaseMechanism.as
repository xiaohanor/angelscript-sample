
asset SummitWindupCrossBowReleaseMechanismMeltSettings of USummitMeltSettings
{
	MaxHealth = 1.0;
}

UCLASS(Abstract)
class ASummitWindupCrossBowReleaseMechanism : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltingComp;
	default MeltingComp.DefaultMeltSettings = SummitWindupCrossBowReleaseMechanismMeltSettings;


	UPROPERTY(EditInstanceOnly)
	ASummitWindupCrossBow CrossBow;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeltingComp.OnMelted.AddUFunction(this, n"OnMelted");
		MeltingComp.OnRestored.AddUFunction(this, n"OnRestored");
	}

	UFUNCTION()
	private void OnRestored()
	{
		if(CrossBow == nullptr)
			return;

		CrossBow.Restore();
	}

	UFUNCTION()
	private void OnMelted()
	{
		if(CrossBow == nullptr)
		{
			devError(f"{this} has no added 'CrossBow'. Set it on the instance");
			return;
		}

		/** That's when the hook attaches to the crossbow
		 * Threshold is hard coded in BP :)))
		 */
		if(GetWindupAlpha() >= 0.95)
		{
			CrossBow.Release();
		}
	}

	UFUNCTION()
	float GetWindupAlpha() const
	{
		if(CrossBow == nullptr)
			return 0;

		return CrossBow.GetWindupAmount() / 1;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeltingComp.Update(DeltaTime);
	}
};