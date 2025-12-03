event void FSanctuaryTiltingPlatformSignature();

class ASanctuaryTiltingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USanctuaryFauxRotateComponent SanctuaryFauxRotateComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryPlayerWeightComponent SanctuaryPlayerWeightComponent;

	UPROPERTY(EditAnywhere)
	float BreakAngle = 5.0;

	bool bIsBroken = false;

	UPROPERTY()
	FSanctuaryTiltingPlatformSignature OnBreak;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Angle = Math::Abs(Math::RadiansToDegrees(SanctuaryFauxRotateComponent.CurrentRotation));

//		PrintToScreen("Angle: " + Angle, 0.0, FLinearColor::Green);
	
		if (!bIsBroken && Angle > BreakAngle)
		{
			bIsBroken = true;
			BP_OnBreak();
			OnBreak.Broadcast();

			SanctuaryPlayerWeightComponent.AddDisabler(this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnBreak()
	{

	}
}