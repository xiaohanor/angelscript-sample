class AStoneBossTransitionSkyBoxManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SpriteName = "Target";
	default Visual.SetWorldScale3D(FVector(500.0));
#endif

	UFUNCTION()
	void SetBPSky(bool bIsAlterateSkyBox, float BlendTime)
	{
		AGameSky::Get().SetAlternateLightingEnabledWithBlend(bIsAlterateSkyBox, 2.0);
	}
};