event void FSanctuaryLightRayResponseSignature(ASanctuaryPerchableLightRay LightRay);

class USanctuaryLightRayResponseComponent : UActorComponent
{
	UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryLightRayResponseSignature OnIlluminate;
	UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryLightRayResponseSignature OnUnilluminate;

	bool bIsIlluminated;


	void Illuminated(ASanctuaryPerchableLightRay LightRay)
	{
		if(bIsIlluminated)
			return;

		OnIlluminate.Broadcast(LightRay);
		bIsIlluminated = true;
	}

	void StopIlluminate(ASanctuaryPerchableLightRay LightRay)
	{
		OnUnilluminate.Broadcast(LightRay);
		bIsIlluminated = false;
	}


}