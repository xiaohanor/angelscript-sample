UCLASS(Abstract)
class UKiteTownVOEffectEventHandler : UHazeEffectEventHandler
{
	//Bounce Kite
	UFUNCTION(BlueprintEvent)
	void Bounce(FKiteTownVOEffectEventParams Params) {}

	//Zip Kite
	UFUNCTION(BlueprintEvent)
	void ZipGrappleStarted(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void ZipGrappleConnected(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void ZipStarted(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void ZipLaunchUp(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void ZipLanded(FKiteTownVOEffectEventParams Params) {}

	//Launch Kite
	UFUNCTION(BlueprintEvent)
	void LaunchGrappleStarted(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void LaunchEnterTunnel(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void LaunchExitTunnel(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void LaunchStartFlight(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void LaunchStopFlight(FKiteTownVOEffectEventParams Params) {}

	//Kite Flight
	UFUNCTION(BlueprintEvent)
	void ActivateFlight(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void DeactivateFlight(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void FlightBoost(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void DespawnFlightCompanion(FKiteTownVOEffectEventParams Params) {}
	UFUNCTION(BlueprintEvent)
	void MissFlightRing(FKiteTownVOEffectEventParams Params) {}
}

struct FKiteTownVOEffectEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

namespace KiteTown
{
	FKiteTownVOEffectEventParams GetVOEffectEventParams(AHazePlayerCharacter Player)
	{
		FKiteTownVOEffectEventParams Params;
		Params.Player = Player;
		return Params;
	}
}