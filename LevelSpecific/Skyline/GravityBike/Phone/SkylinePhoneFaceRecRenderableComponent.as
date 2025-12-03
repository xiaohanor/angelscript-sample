class USkylinePhoneFaceRecRenderableComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(TListedActors<ASkylinePhoneProgressSpline>().Single != nullptr)
			TListedActors<ASkylinePhoneProgressSpline>().Single.ActorsToRenderFaceRecognition.Add(Owner);
	}
};