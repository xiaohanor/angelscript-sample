
enum ELFOMode
{
	Sine,
	Tri,
	Saw,
	Square,
	Random
}

UCLASS(Abstract)
class UTest_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	float Cycle = 0.0;
	bool bRising = true;

	UFUNCTION(BlueprintPure)
	float LFO(float DeltaTime, const ELFOMode Mode, const float Frequency = 50.0)
	{
		switch(Mode)
		{
			case(ELFOMode::Sine):
				Cycle += (Frequency * DeltaTime);

				if(Cycle >= 1.0)				
					Cycle -= 1.0;

				return Math::Sin(Cycle * 2 * PI);
			case ELFOMode::Tri:
			{
				if(bRising)
					Cycle += (Frequency * DeltaTime);
				else
					Cycle -= (Frequency * DeltaTime);
			
				if(Cycle >= 1.0)
				{
					bRising = false;
				}
				else if(Cycle <= 0)
				{
					bRising = true;
				}

				return Cycle;
			}
			case ELFOMode::Saw:
			{
				Cycle += (Frequency * DeltaTime);

				if(Cycle >= 1.0)				
					Cycle -= 1.0;

				return Cycle * 2 - 1;
			}
			case ELFOMode::Square:
			{
				Cycle += (Frequency * DeltaTime);

				if(Cycle >= 1.0)				
					Cycle -= 1.0;

				return Cycle > 0.5 ? 1 : -1;
			}
			case ELFOMode::Random:
			{
				const float RandomVal = Math::RandRange(0.3, 3.0);
				Cycle += (RandomVal * DeltaTime);

				if(Cycle >= 1.0)				
					Cycle -= 1.0;

				return Math::Sin(Cycle * 2 * PI);
				
			}
			default:
				return 0.0;
				
		}		

		// Removed warnings (GK)
		// PrintToScreenScaled("Seconds: " + Cycle);
		//CachedTime = Time::GetRealTimeSeconds();
		// return Cycle * 2 - 1.0;
	}
	
}