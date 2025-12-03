enum EWindIntensity
{
	Normal,
	Strong
}

event void WindDirectionChanged(FVector Direction, FVector Location);
event void WindIntensityChanged(EWindIntensity Intensity);

class UWindDirectionComponent : UActorComponent
{
	WindDirectionChanged OnWindDirectionChanged;
	WindIntensityChanged OnWindIntensityChanged;

	private FVector WindDirection_Internal;
	private EWindIntensity WindIntensity_Internal;
	UNiagaraComponent WindNiagara;

	void SetWindDirection(FVector InWindDirection, FVector Location)
	{
		WindDirection_Internal = InWindDirection;
		OnWindDirectionChanged.Broadcast(WindDirection_Internal, Location);
	}

	void SetWindIntensity(EWindIntensity Intensity)
	{
		WindIntensity_Internal = Intensity;
		OnWindIntensityChanged.Broadcast(WindIntensity_Internal);
	}

	FVector GetWindDirection() const property
	{
		return WindDirection_Internal;
	}

	FRotator GetWindDirectionAsRotation() const property
	{
		return FRotator::MakeFromX(WindDirection_Internal);
	}

	EWindIntensity GetWindIntensity() const property
	{
		return WindIntensity_Internal;
	}

	bool GetbIsStrongWind() const property
	{
		return WindIntensity_Internal == EWindIntensity::Strong;
	}

	FVector GetWindLocation() const property
	{
		const FVector LineStart = Game::GetZoe().ViewLocation;
		const FVector LineEnd = LineStart + (Game::GetZoe().ViewRotation.ForwardVector * 10000.0);
		const FVector PlaneOrigin = FVector::ZeroVector;
		const FVector PlaneNormal = FVector::UpVector;
		return Math::LinePlaneIntersection(LineStart, LineEnd, PlaneOrigin, PlaneNormal);
	}
}