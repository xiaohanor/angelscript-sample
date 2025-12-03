asset SkippingStonesChargeCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |                               '·                               |
	    |                             .'  ·                              |
	    |                            ·     '                             |
	    |                          .'       '.                           |
	    |                         ·           .                          |
	    |                       .'             ·                         |
	    |                      ·                ·                        |
	    |                    .'                  '.                      |
	    |                   ·                      ·                     |
	    |                 .'                        '.                   |
	    |                ·                            ·                  |
	    |              ·'                              '·                |
	    |            .'                                  '·              |
	    |          ·'                                      '·.           |
	    |       .·'                                           '·.        |
	0.0 |....··'                                                 '··.....|
	    ------------------------------------------------------------------
	    0.05                                                          0.95
	*/
	AddAutoCurveKey(0.05, 0.0);
	AddAutoCurveKey(0.5, 1.0);
	// AddCurveKeyBrokenTangent(0.5, 1.0, 2.902841, -4.103428);
	AddAutoCurveKey(0.95, 0.0);
};

namespace SkippingStones
{
	// Pickup
	const float PickupEndDelay = 0.67;
	const FVector StoneRelativeLocation = FVector(0, -5, -5);
	const FRotator StoneRelativeRotation = FRotator(0, -90, 90);

	// Charge
	const float MinChargeAlpha = 0.1;
	const float ChargeCurveSpeed = 0.35;

	// Throw
	const float ThrowEndDelay = 0.37;
	const float MaxThrowSpeed = 2000;
	const float MinThrowSpeed = 900;

	//Camera
	const float YawClampAngle = 30;
	const float PitchClampAngle = 30;
	
	// Stone Movement
	const float Gravity = 700;
	const float SkippingStonesVerticalRestitution = 0.8;
	const float SkippingStonesHorizontalRestitution = 0.8;
	const float HorizontalVelocityThreshold = 500;
	const float VerticalAngleThreshold = 15;
	const float InwardsCurveAngle = 0.15;
	const float Drag = 0.1;
};