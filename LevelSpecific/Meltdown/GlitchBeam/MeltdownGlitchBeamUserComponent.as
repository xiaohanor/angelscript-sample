class UMeltdownGlitchBeamUserComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AMeltdownGlitchBeam> BeamClass;
	UPROPERTY()
	UForceFeedbackEffect FireForceFeedback;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};