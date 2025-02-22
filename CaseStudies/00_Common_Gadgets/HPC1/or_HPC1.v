//
// partially taken from https://github.com/cassiersg/fullverif
//
// -----------------------------------------------------------------
// COMPANY : Ruhr University Bochum
// AUTHOR  : Amir Moradi (amir.moradi@rub.de)
// DOCUMENT: https://eprint.iacr.org/2021/569/
// -----------------------------------------------------------------
//
//
// Copyright (c) 2021, David Knichel, Amir Moradi, Nicolai M�ller, Pascal Sasdrich
//
// All rights reserved.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTERS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Please see LICENSE and README for license and further instructions.
//

module or_HPC1 
#(parameter security_order = 2, parameter pipeline = 1)
(ina, inb, rnd, clk, outt);

parameter integer d = security_order+1;

`include "MSKand_HPC1.vh"

input  [d-1:0] ina;
input  [d-1:0] inb;
output [d-1:0] outt;
input clk;
input [and_pini_nrnd-1:0] rnd;

wire [d-1:0] inb_ref;
reg  [d-1:0] ina_delay;

wire [ref_n_rnd-1:0] rnd_ref;
assign rnd_ref = rnd[ref_n_rnd-1:0];

wire [and_pini_mul_nrnd-1:0] rnd_mul;
assign rnd_mul = rnd[and_pini_nrnd-1:ref_n_rnd];

wire [d-1:0] not_ina;
wire [d-1:0] not_inb;
wire [d-1:0] not_outt;

assign not_ina[0]     = ~ina[0];
assign not_ina[d-1:1] =  ina[d-1:1];

assign not_inb[0]     = ~inb[0];
assign not_inb[d-1:1] =  inb[d-1:1];

if (pipeline != 0) begin 
    always @(posedge clk)
        ina_delay <= not_ina;
end else begin
    always @(*)
        ina_delay <= not_ina;
end

MSKref #(.d(d)) rfrsh (.in(not_inb), .clk(clk), .out(inb_ref), .rnd(rnd_ref));
MSKand_DOM #(.d(d)) mul (.ina(ina_delay), .inb(inb_ref), .clk(clk), .rnd(rnd_mul), .out(not_outt));

assign outt[0]     = ~not_outt[0];
assign outt[d-1:1] =  not_outt[d-1:1];

endmodule